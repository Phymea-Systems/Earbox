"""
Mask R-CNN for maize kernel counting and segmentation from Phymea-systems
using Mask R-CNN implementation from https://github.com/matterport/Mask_RCNN
Licensed under the MIT License (see LICENSE for details)

Written by Timothé Leroux
"""

import matplotlib
# Agg backend runs without a display
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os
import sys
import random
import json
from datetime import datetime
import pickle
import numpy as np
import skimage.io
import skimage.morphology
import skimage.util
import skimage.color
from imgaug import augmenters as iaa
import tkinter as tk
from tkinter import filedialog

# Root directory of the project
ROOT_DIR = os.path.dirname(os.path.realpath(__file__))

# Import Mask RCNN
sys.path.append(ROOT_DIR)  # To find local version of the library
from mrcnn.config import Config
from mrcnn import utils
from mrcnn import model as modellib
from mrcnn import visualize
from mrcnn.model import log


today = datetime.today().strftime('%Y-%m-%d')
DEFAULT_OUTPUT_DIR = os.path.join(ROOT_DIR, "outputs", "output_"+today)

############################################################
#  Configurations
############################################################

class MaizeConfig(Config):
    """Configuration for training on the maize segmentation dataset."""
    NAME = "maize"
    IMAGES_PER_GPU = 3
    NUM_CLASSES = 1 + 1  # Background + kernels
    NB_EPOCH = 99
    VALIDATION_STEPS = 75
    
    # Train "all" weights or only "heads" layers
    LAYERS = "all"
    
    # Learning rate and momentum
    # The Mask RCNN paper uses lr=0.02, but on TensorFlow it causes
    # weights to explode. Likely due to differences in optimizer
    # implementation.
    LEARNING_RATE = 0.001
    LEARNING_MOMENTUM = 0.9
    
    # Don't exclude based on confidence. Since we have two classes
    # then 0.5 is the minimum anyway as it picks between maize and BG
    DETECTION_MIN_CONFIDENCE = 0

    # Backbone network architecture
    # Supported values are: resnet50, resnet101
    BACKBONE = "resnet50"
    
    # Input image resizing
    # Random crops of size 512x512
    IMAGE_RESIZE_MODE = "crop"
    IMAGE_MIN_DIM = 512
    IMAGE_MAX_DIM = 512
    IMAGE_MIN_SCALE = 1.0

    # Length of square anchor side in pixels
    RPN_ANCHOR_SCALES = (8, 16, 32, 64, 128)

    # ROIs kept after non-maximum supression (training and inference)
    POST_NMS_ROIS_TRAINING = 1000
    POST_NMS_ROIS_INFERENCE = 2000

    # Non-max suppression threshold to filter RPN proposals.
    RPN_NMS_THRESHOLD = 0.9

    # How many anchors per image to use for RPN training
    RPN_TRAIN_ANCHORS_PER_IMAGE = 256

    # Image mean (RGB)
    MEAN_PIXEL = np.array([43.53, 39.56, 48.22])

    # If enabled, resizes instance masks to a smaller size to reduce
    # memory load. Recommended when using high-resolution images.
    USE_MINI_MASK = True
    MINI_MASK_SHAPE = (56, 56)  # (height, width) of the mini-mask

    # Number of ROIs per image to feed to classifier/mask heads
    # The Mask RCNN paper uses 512 but often the RPN doesn't generate
    # enough positive proposals to fill this and keep a positive:negative
    # ratio of 1:3. You can increase the number of proposals by adjusting
    # the RPN NMS threshold.
    TRAIN_ROIS_PER_IMAGE = 256

    # Maximum number of ground truth instances to use in one image
    MAX_GT_INSTANCES = 200

    # Max number of final detections per image
    DETECTION_MAX_INSTANCES = 400


class MaizeInferenceConfig(MaizeConfig):
    # Set batch size to 1 to run one image at a time
    GPU_COUNT = 1
    IMAGES_PER_GPU = 1
    # Don't resize imager for inferencing
    IMAGE_RESIZE_MODE = "pad64"
    # Non-max suppression threshold to filter RPN proposals.
    # You can increase this during training to generate more propsals.
    RPN_NMS_THRESHOLD = 0.7


############################################################
#  Dataset
############################################################

class MaizeDataset(utils.Dataset):
    def load(self, dataset_dir, subset, split=None, indexes=None):
        """Load a subset of the maize dataset.

        dataset_dir: Root directory of the dataset
        subset: name of the sub-directory to load
        """
        
        self.add_class("maize", 1, "kernel")
        if subset:
            dataset_dir = os.path.join(dataset_dir, subset)
        image_ids = next(os.walk(dataset_dir))[1]

        if indexes:
            image_ids = image_ids[indexes]
        if split:
            self.split_ids = random.sample(image_ids, len(image_ids)*split/100)
            image_ids = list(set(image_ids) - set(self.split_ids))
        for image_id in image_ids:
            blended_exists = False
            if os.path.exists(os.path.join(dataset_dir, image_id,"BLENDED.png")):
                blended_exists = True
            else:
                # Create 4 channel images from RGB and IR pictures
                print(f"creating blended image {os.path.join(dataset_dir, image_id,'BLENDED.png')}")
                rgb = skimage.io.imread(os.path.join(dataset_dir, image_id, "RGB.png"))
                if os.path.exists(os.path.join(dataset_dir, image_id,"IR.png")):
                    ir = skimage.io.imread(os.path.join(dataset_dir, image_id, "IR.png"))
                    irgray = skimage.color.rgb2gray(ir)
                    irgray_ubyte = skimage.util.img_as_ubyte(irgray)
                    blendedimg = np.dstack((rgb,irgray_ubyte))
                    skimage.io.imsave(os.path.join(dataset_dir, image_id,"BLENDED.png"),blendedimg)
                    blended_exists = True                    
                else:
                    print(f"No IR image found for id {image_id}: id will not be used.")

            # append image to dataset
            if blended_exists:
                self.add_image(
                    "maize",
                    image_id=image_id,
                    path=os.path.join(dataset_dir, image_id, "BLENDED.png")
                )
                
    def load_mask(self, image_id):
        """Generate instance masks for an image.
       Returns:
        masks: A bool array of shape [height, width, instance count] with
            one mask per instance.
        class_ids: a 1D array of class IDs of the instance masks.
        """
        info = self.image_info[image_id]
        # Get mask directory from image path
        mask_dir = os.path.dirname(info['path'])

        # Read mask files from .png image
        mask = []
        m_size = None
        for f in next(os.walk(mask_dir))[2]:
            if f == "mask.png":
                m = skimage.io.imread(os.path.join(mask_dir, f)).astype(np.bool)
                m_size = m.shape
                mlabels = skimage.morphology.label(m)
                for label in range(1,np.max(mlabels)+1):
                    mask.append(mlabels==label)
        if mask :       
            mask = np.stack(mask, axis=-1)
        elif m_size :
            mask = np.zeros(m_size)
        else :
            img = skimage.io.imread(info["path"])
            mask = np.zeros(img.shape)
        # Return mask, and array of class IDs of each instance. Since we have
        # one class ID, we return an array of ones
        if len(mask.shape) > 2:
            class_ids = np.ones([mask.shape[-1]], dtype=np.int32)
        else:
            class_ids = np.array([], dtype=np.int32)
        return mask, class_ids

    def image_path(self, image_id):
        """Return the path of the image."""
        info = self.image_info[image_id]
        if info["source"] == "maize":
            return info["id"]
        else:
            super(self.__class__, self).image_reference(image_id)
            
    def size(self):
        return len(self.image_info)


############################################################
#  Training
############################################################

def train(model, dataset_dir, subset, crossvalset=None, crossval_split=30):
    """Train the model."""
    if crossvalset:
        # Cross-validate on a separate dataset
        # Training dataset
        print(f"Loading dataset: {subset}")
        dataset_train = MaizeDataset()
        dataset_train.load(dataset_dir, subset)
        dataset_train.prepare()
        # Cross-Validation dataset
        print(f"Loading cross-validation dataset: {crossvalset}")
        dataset_xval = MaizeDataset()
        dataset_xval.load(dataset_dir, crossvalset)
        dataset_xval.prepare()
    else:
        # Training dataset
        print(f"Loading dataset: {subset} with {crossval_split}% samples for cross-validation")
        dataset_train = MaizeDataset()
        dataset_train.load(dataset_dir, subset, crossval_split)
        dataset_train.prepare()
        # Cross-Validation dataset
        dataset_xval = MaizeDataset()
        dataset_xval.load(dataset_dir, subset, indexes=dataset_train.split_ids)
        dataset_xval.prepare()      

    # Image augmentation
    # http://imgaug.readthedocs.io/en/latest/source/augmenters.html
    augmentation = iaa.SomeOf((0, 2), [
        iaa.Fliplr(0.5),
        iaa.Flipud(0.5),
        iaa.OneOf([iaa.Affine(rotate=90),
                   iaa.Affine(rotate=180),
                   iaa.Affine(rotate=270)]),
        iaa.Multiply((0.8, 1.5)),
        iaa.GaussianBlur(sigma=(0.0, 5.0))
    ])

    print(f"Train network layers: {config.LAYERS}, LR: {config.LEARNING_RATE}, Epochs: {config.NB_EPOCH}")
    
    config.STEPS_PER_EPOCH = dataset_train.size() // config.IMAGES_PER_GPU
    if config.VALIDATION_STEPS > dataset_xval.size():
        config.VALIDATION_STEPS = dataset_xval.size()
        
    model.train(dataset_train, dataset_xval,
                learning_rate=config.LEARNING_RATE,
                epochs=config.NB_EPOCH,
                augmentation=augmentation,
                layers=config.LAYERS)

############################################################
#  RLE Encoding
############################################################

def rle_encode(mask):
    """Encodes a mask in Run Length Encoding (RLE).
    Returns a string of space-separated values.
    """
    assert mask.ndim == 2, "Mask must be of shape [Height, Width]"
    # Flatten it column wise
    m = mask.T.flatten()
    # Compute gradient. Equals 1 or -1 at transition points
    g = np.diff(np.concatenate([[0], m, [0]]), n=1)
    # 1-based indicies of transition points (where gradient != 0)
    rle = np.where(g != 0)[0].reshape([-1, 2]) + 1
    # Convert second index in each pair to lenth
    rle[:, 1] = rle[:, 1] - rle[:, 0]
    return " ".join(map(str, rle.flatten()))


def rle_decode(rle, shape):
    """Decodes an RLE encoded list of space separated
    numbers and returns a binary mask."""
    rle = list(map(int, rle.split()))
    rle = np.array(rle, dtype=np.int32).reshape([-1, 2])
    rle[:, 1] += rle[:, 0]
    rle -= 1
    mask = np.zeros([shape[0] * shape[1]], np.bool)
    for s, e in rle:
        assert 0 <= s < mask.shape[0]
        assert 1 <= e <= mask.shape[0], "shape: {}  s {}  e {}".format(shape, s, e)
        mask[s:e] = 1
    # Reshape and transpose
    mask = mask.reshape([shape[1], shape[0]]).T
    return mask


def mask_to_rle(image_id, mask, scores):
    "Encodes instance masks."
    order = np.argsort(scores)[::-1] + 1  # 1-based descending
    # Loop over instance masks
    lines = []
    for o in order:
        m = np.where(mask == o, 1, 0)
        # Skip if empty
        if m.sum() == 0.0:
            continue
        rle = rle_encode(m)
        lines.append("{}, {}".format(image_id, rle))
    return "\n".join(lines)


def clean_and_label(image_id, masks, scores):
    "Clean mask overlaps, holes, small objects, and label by score"
    assert masks.ndim == 3, "Mask must be [H, W, count]"
    # Remove mask overlaps
    # Multiply each instance mask by its score order
    # then take the maximum across the last dimension
    order = np.argsort(scores)[::-1] + 1  # 1-based descending
    print(f"id: {image_id}, nb_items: {masks.shape[2]}, im_size: {masks.shape[:2]}")
    labels = np.max(masks * np.reshape(order, [1, 1, -1]), -1)
    mask_empty = np.zeros([labels.shape[0], labels.shape[1]], np.int32)
    mask = mask_empty.copy()
    # Loop over instance masks
    lines = []
    for o in order:
        # rly not optimized...
        objmask = labels==o
        objdilated = skimage.morphology.dilation(objmask, skimage.morphology.disk(2))
        maskwithobj = mask[objdilated]
        while np.max(maskwithobj) != 0:
            objdilated = objmask
            objmask = skimage.morphology.erosion(objmask, skimage.morphology.disk(2))
            maskwithobj = mask[objdilated]
        mask = mask+objmask
    
    mask[mask > 1] = 0
    mask = mask > 0
    mask = skimage.morphology.remove_small_objects(mask, 200)
    mask = skimage.morphology.remove_small_holes(mask, 200)
    mask = skimage.morphology.opening(mask, skimage.morphology.disk(7))
    labels[~mask] = 0
    return labels


############################################################
#  Detection
############################################################

def detect(model, dataset_dir, subset, results_dir):
    """Run detection on images in the given directory."""
    print("Running on {}".format(dataset_dir))

    submit_dir = "detect_{:%Y%m%dT%H%M%S}".format(datetime.now())
    submit_dir = os.path.join(results_dir, submit_dir)
    if not os.path.exists(submit_dir):
        os.makedirs(submit_dir)

    # Read dataset
    dataset = MaizeDataset()
    dataset.load(dataset_dir, subset)
    dataset.prepare()
    # Load over images
    csv_content = []
    _, ax = plt.subplots(1, figsize=(16, 16))
    for image_id in dataset.image_ids:
        # Load image and run detection
        image = dataset.load_image(image_id)
        source_id = dataset.image_info[image_id]["id"]
        # Detect objects
        r = model.detect([image], verbose=0)[0]
        # Save image with masks
        visualize.display_instances(
            image, r['rois'], r['masks'], r['class_ids'],
            dataset.class_names, r['scores'],
            show_bbox=False, show_mask=False,
            title="Predictions",show_caption=False, ax=ax)
        plt.show()
        plt.savefig("{}/{}.png".format(submit_dir, source_id))
        plt.cla()
        
        # Clean and label masks
        label_mask = clean_and_label(source_id, r["masks"], r["scores"])
        
        # Save cleaned binary mask
        skimage.io.imsave("{}/{}_mask.png".format(submit_dir, source_id), label_mask>0)
        
        # Encode image to RLE. Returns a string of multiple lines
        rle = mask_to_rle(source_id, label_mask, r["scores"])
        csv_content.append(rle)

    # Save to csv file
    csv_content = "ImageId,EncodedPixels\n" + "\n".join(csv_content)
    file_path = os.path.join(submit_dir, "rle_encoded_masks.csv")
    with open(file_path, "w") as f:
        f.write(csv_content)
    print("Saved to ", submit_dir)

############################################################
#  Scoring
############################################################

def score(model, dataset_dir, subset, results_dir):
    """Run scoring on images in the given directory."""
    print("Running on {}".format(dataset_dir))
    # Create directory
    scores_dir = "scores_{:%Y%m%dT%H%M%S}".format(datetime.now())
    scores_dir = os.path.join(results_dir, scores_dir)
    if not os.path.exists(scores_dir):
        os.makedirs(scores_dir)

    dataset = MaizeDataset()
    dataset.load(dataset_dir, subset)
    dataset.prepare()

    image_id = random.choice(dataset.image_ids)
    image, image_meta, gt_class_id, gt_bbox, gt_mask =\
        modellib.load_image_gt(dataset, config, image_id, use_mini_mask=False)
    info = dataset.image_info[image_id]
    print("image ID: {}.{} ({}) {}".format(info["source"], info["id"], image_id, 
                                        dataset.image_path(image_id)))
    print("Original image shape: ", modellib.parse_image_meta(image_meta[np.newaxis,...])["original_image_shape"][0])
    
    # Run object detection
    results = model.detect_molded(np.expand_dims(image, 0), np.expand_dims(image_meta, 0), verbose=1)
    
    # Display results
    r = results[0]
    log("gt_class_id", gt_class_id)
    log("gt_bbox", gt_bbox)
    log("gt_mask", gt_mask)
    # Compute AP over range 0.5 to 0.95 and print it
    utils.compute_ap_range(gt_bbox, gt_class_id, gt_mask,
                        r['rois'], r['class_ids'], r['scores'], r['masks'],
                        verbose=1)
    _, ax = plt.subplots(1, figsize=(16, 16))
    visualize.display_differences(
        image,
        gt_bbox, gt_class_id, gt_mask,
        r['rois'], r['class_ids'], r['scores'], r['masks'],
        dataset.class_names, ax=ax,
        show_box=False, show_mask=False,
        iou_threshold=0.5, score_threshold=0.5)
    plt.show()
    plt.savefig("{}/{}.png".format(scores_dir, image_id))
    plt.cla()

############################################################
#  Command Line
############################################################

if __name__ == '__main__':
    import argparse

    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Mask R-CNN for maize kernel counting and segmentation')
    parser.add_argument("command",
                        metavar="<command>",
                        help="'train' or 'detect'")
    parser.add_argument('--dataset', required=True,
                        metavar="/path/to/dataset/",
                        help='Root directory of the dataset')
    parser.add_argument('--weights', required=False,
                        default="last",
                        metavar="/path/to/weights.h5",
                        help="Path to weights .h5 file or 'last'")
    parser.add_argument('--output', required=False,
                        default=DEFAULT_OUTPUT_DIR,
                        metavar="/path/to/output/",
                        help='Output directory (default=outputs/output_%Y-%m-%d)')
    parser.add_argument('--subset', required=False,
                        metavar="Dataset sub-directory",
                        help="Subset of dataset to run prediction on")
    parser.add_argument('--crossval', required=False,
                        metavar="Cross-validation dataset sub-directory",
                        help="Subset of dataset to cross-validate on")
    args = parser.parse_args()

    args.dataset=os.path.normpath(args.dataset)
    args.output=os.path.normpath(args.output)

    print("Dataset: ", args.dataset)
    if args.subset:
        print("Subset: ", args.subset)
    print("Weights: ", args.weights)
    print("Output directory: ", args.output)

    logs_dir = os.path.join(args.output, "logs")
    results_dir = os.path.join(args.output, "results")
    scores_dir = os.path.join(args.output, "scores")

    # Create directories
    for d in (args.output, logs_dir, results_dir, scores_dir):
        if not os.path.exists(d):
            os.makedirs(d)
    
    # Configurations
    if args.command == "train":
        config = MaizeConfig()
    else:
        config = MaizeInferenceConfig()
    config.display()

    # Create model
    if args.command == "train":
        model = modellib.MaskRCNN(mode="training", config=config,
                                  model_dir=logs_dir)
    else:
        model = modellib.MaskRCNN(mode="inference", config=config,
                                  model_dir=logs_dir)

    # Path to weights file to load or "last"
    if args.weights.lower() == "last":
        # Find last trained weights
        weights_path = model.find_last()
    else:
        weights_path = os.path.normpath(args.weights)

    # Load weights
    print("Loading weights ", weights_path)
    model.load_weights(weights_path, by_name=True)

    # Train or evaluate
    if args.command == "train":
        train(model, args.dataset, args.subset, args.crossvalset)
    elif args.command == "detect":
        detect(model, args.dataset, args.subset, results_dir)
    elif args.command == "score":
        score(model, args.dataset, args.subset, results_dir)
    else:
        print("'{}' is not recognized. "
              "Use 'train', 'detect' or 'score'".format(args.command))
