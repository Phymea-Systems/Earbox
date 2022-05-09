# -*- coding: utf-8 -*-
import signal
import subprocess, os, sys, RPi.GPIO as GPIO, time, csv, datetime
import paramiko
import numpy as np
from PIL import Image
import scipy.ndimage as nd
import scipy.misc as misc

import pygame, pygame.gfxdraw, string
from pygame.locals import *

from threading import Thread

pygame.mixer.init()
pygame.mixer.music.set_volume(0.7) #Met le volume à 0.5 (moitié)

GPIO.setwarnings(False)
GPIO.cleanup()
# to use Raspberry Pi board pin numbers
GPIO.setmode(GPIO.BOARD)

#Set up GPIO output channel
        #RELAY
GPIO.setup(33, GPIO.OUT, initial=GPIO.HIGH)#GPIO Relay 3 Resistance
GPIO.setup(36, GPIO.OUT, initial=GPIO.HIGH)#GPIO Relay 1 VISI
GPIO.setup(38, GPIO.OUT, initial=GPIO.HIGH)#GPIO Relay 2 IR
        #LED button
GPIO.setup(15, GPIO.OUT, initial=GPIO.LOW)#LED RED
GPIO.setup(13, GPIO.OUT, initial=GPIO.LOW)#LED GREEN
GPIO.setup(11, GPIO.OUT, initial=GPIO.LOW)#LED BLUE
        #MOTOR pins
GPIO.setup(16, GPIO.OUT, initial=GPIO.LOW)#GPIO ING motorRoller
GPIO.setup(18, GPIO.OUT, initial=GPIO.LOW)#GPIO ROT motorRoller
GPIO.setup(22, GPIO.OUT, initial=GPIO.LOW)#GPIO CTRL Guillotine ancien 37
#GPIO.setup(12, GPIO.OUT, initial=GPIO.LOW)#GPIO enable motor

#Set up GPIO input channel
GPIO.setup(40, GPIO.IN, pull_up_down=GPIO.PUD_UP)#Button RED
GPIO.setup(32, GPIO.IN, pull_up_down=GPIO.PUD_UP)#Button GREEN
GPIO.setup(37, GPIO.IN, pull_up_down=GPIO.PUD_UP)#Button BLUE ancien 22
GPIO.setup(35, GPIO.IN, pull_up_down=GPIO.PUD_UP)#Door_State

#configuration SSH
paramiko. util. log_to_file ( 'paramiko.log ') #permet d'eviter l'erreur : No handlers could be found for logger "paramiko.transport"
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

#configuration pygame
driver = 'x11'
os.putenv('SDL_VIDEODRIVER', driver)

#environment variables
LOCAL_USER = os.environ['USER']
DISTANT_USER = os.environ['DISTANT_USER']

ROOT_DIR = os.environ['ROOT_DIRECTORY']

UI_DIR = os.path.join(ROOT_DIR, "Interface")
CALIB_DIR = os.path.join(ROOT_DIR, "Calibration")
DETECTION_DIR = os.path.join(ROOT_DIR, "Detection")

DISTANT_ROOT_DIR = os.environ['DISTANT_ROOT_DIRECTORY']
DISTANT_DIR = os.environ['DISTANT_CAPTURE_DIRECTORY']

DISTANT_PWD = os.environ['DISTANT_PWD']

#Variables de fonctionnement
fileparam = UI_DIR + "/Log/param.txt" #fichier de parametres (nombre de capture sauvegardé)
filesession = UI_DIR + "/Log/session.txt" #fichier de session (sauvegarde le nom de la dernière session choisie)
data_csv =  UI_DIR + "/Log/log_data.csv" #fichier de parametres (nombre de capture sauvegardé)
calib_local = CALIB_DIR + "/calib_local.txt" #fichier avec données de calibration pour la camera_local
calib_distant = CALIB_DIR + "/calib_distant.txt" #fichier avec données de calibration pour la camera_distant

capture_dir_distant = DISTANT_DIR

ls_info = []#Creation d'un fichier 'infos' contenant les infos systems pour etre affichées
ls_info_col = []
list_ID_filter =[]
calib_param_local = []
calib_param_distant = []
buttonstate = 0
check=1
pinR1=36#GPIO Relay 1 VISI 36
pinR2=38#GPIO Relay 2 IR 38
pinRes=33#GPIO Relay 3 Resistance
ARDUINO_CTRL_DOOR = 22
DOOR_STATE_PIN = 35
pinING=16
pinROT=18
#Constantes graphiques
mar = 60 #marge sur y

version_capture = "zea_ui_v1.3"
ls_uc = ("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9","&","(",")","-","_")
ls_uc_date = ("0","1","2","3","4","5","6","7","8","9","/",":")
########################################################################
##Classes
class Copythread(Thread):
        def __init__(self, client, imageRGB_path, imageIR_path, local_dir, distant_dir, session):
                Thread.__init__(self)
                self.client = client
                self.imageRGB_path = imageRGB_path
                self.imageIR_path = imageIR_path
                self.local_dir = local_dir
                self.distant_dir = distant_dir
                self.session = session
        def run(self):
                self.get_distant_file(self.imageRGB_path)
                self.get_distant_file(self.imageIR_path)
        def get_distant_file(self, filename):
                filepath_campi = self.distant_dir + filename
                filepath_earboxpi = self.local_dir + self.session + "/" + filename
                # ouvre un client ftp
                with self.client.open_sftp() as ftp_client:
                        #print "SFTP OPEN"
                        ftp_client.get(filepath_campi, filepath_earboxpi)
                        ftp_client.remove(filepath_campi)
                #print "SFTP CLOSE"        
##Functions   
def handler(signum, frame):
	pass

def REDbutton(channel):
        #print 'RED pressed'
        global buttonstate
        buttonstate = "RB"
        pygame.mixer.music.load(UI_DIR + "/Voices/valid.mp3")
        pygame.mixer.music.play(0,0.0) 
def GREENbutton(channel):
        #print 'GREEN pressed'
        global buttonstate
        buttonstate = "GB"
        pygame.mixer.music.load(UI_DIR + "/Voices/valid.mp3")
        pygame.mixer.music.play(0,0.0) 
def BLUEbutton(channel):
        #print 'BLUE pressed'
        global buttonstate
        buttonstate = "BB"
        pygame.mixer.music.load(UI_DIR + "/Voices/valid.mp3")
        pygame.mixer.music.play(0,0.0)

def validation():
        valid=0
        while valid==0:
               GPIO.output(15,1)
               GPIO.output(13,1)
               time.sleep(0.8)
               GPIO.output(15,0)
               GPIO.output(13,0)
               time.sleep(0.3)
               if buttonstate!= 0 :    
                        valid=1

def validation_all():
        valid=0
        while valid==0:
               GPIO.output(15,1)
               GPIO.output(13,1)
               GPIO.output(11,1)
               time.sleep(0.8)
               GPIO.output(15,0)
               GPIO.output(13,0)
               GPIO.output(11,0)
               time.sleep(0.3)
               if buttonstate!= 0 :
                        valid=1

def ear_capt_button(delay_min): #delay pour mise en veille
        valid=0
        k_a = False
        k_d = False
        k_ctrl = False
        timer_eb = datetime.datetime.now()
        timer_delta= datetime.timedelta(minutes=delay_min)
           
        while valid==0:
                while datetime.datetime.now() - timer_eb > timer_delta: #Fonction de mise en veille
                    global buttonstate
                    pygame.mixer.music.load(UI_DIR + "/Voices/veille.mp3")
                    pygame.mixer.music.play(0,0.0)
                    bck = pygame.Surface(screen.get_size())
                    bck = bck.convert()
                    bck.fill((0,0,0))
                    bck.set_alpha(int(255))
                    screen.blit(bck, (0,0))
                    pygame.display.flip()
                    door_ctrl("close")
                    led_visi_ctrl(0,0)
                    validation() #Freeze en attendant une pression de boutons pour sortir de veille
                    pygame.mixer.music.load(UI_DIR + "/Voices/veille_exit.mp3")
                    pygame.mixer.music.play(0,0.0)                    
                    buttonstate=0
                    init_bck(w,h, ncode, check_para)
                    display_cmd(w, h, "capture", list_ID_filter, 180)
                    display_time(w, h)
                    display_c_amnt(w, h, capture_amt)
                    pygame.display.flip()
                    door_ctrl("open")
                    led_visi_ctrl(0,1)
                    timer_eb = datetime.datetime.now()
                    
                display_time(w, h)
                for event in pygame.event.get():
                        if event.type == pygame.KEYDOWN:
                                if event.key == pygame.K_d:
                                        k_d = True
                                if event.key == pygame.K_a:
                                        k_a = True
                                if event.key == pygame.K_LCTRL:
                                        k_ctrl = True

                        if k_a == True and k_d == True and k_ctrl == True:
                                pygame.mixer.music.load(UI_DIR + "/Voices/admin.mp3")
                                pygame.mixer.music.play(0,0.0)
                                k_a = False
                                k_d = False
                                k_ctrl = False
                                ns = 0
                                while ns <6:
                                        for event in pygame.event.get():
                                              if event.type == pygame.KEYDOWN and event.key == pygame.K_y:
                                                        pygame.mixer.music.load(UI_DIR + "/Voices/welcome.mp3")
                                                        pygame.mixer.music.play(0,0.0)
                                                        ns = 10
                                                        time.sleep(3)
                                                        pygame.quit()
                                                        sys.exit(0)
                                                        #commande pour quitter pygame > lancer startx > quitter python (arrêter le service)
                                              if event.type == pygame.KEYDOWN and event.key == pygame.K_n:
                                                        pygame.mixer.music.load(UI_DIR + "/Voices/valid.mp3")
                                                        pygame.mixer.music.play(0,0.0)
                                                        ns = 10
                                        ns += 0.5
                                        time.sleep(0.5)
                                if ns < 10:
                                        pygame.mixer.music.load(UI_DIR + "/Voices/alert.mp3")
                                        pygame.mixer.music.play(0,0.0)
                                        
                #time.sleep(10)
                GPIO.output(15,1)
                GPIO.output(13,1)
                GPIO.output(11,1)
                time.sleep(0.8)
                GPIO.output(15,0)
                GPIO.output(13,0)
                GPIO.output(11,0)
                time.sleep(0.3)
                if buttonstate!= 0 :  
                        valid=1

def green_only():
        valid=0
        k_a = False
        k_d = False
        k_ctrl = False
        
        while valid==0:
                display_time(w, h)
                for event in pygame.event.get():
                        if event.type == pygame.KEYDOWN:
                                if event.key == pygame.K_d:
                                        k_d = True
                                if event.key == pygame.K_a:
                                        k_a = True
                                if event.key == pygame.K_LCTRL:
                                        k_ctrl = True

                        if k_a == True and k_d == True and k_ctrl == True:
                                pygame.mixer.music.load(UI_DIR + "/Voices/admin.mp3")
                                pygame.mixer.music.play(0,0.0)
                                k_a = False
                                k_d = False
                                k_ctrl = False
                                ns = 0
                                while ns <6:
                                        for event in pygame.event.get():
                                              if event.type == pygame.KEYDOWN and event.key == pygame.K_y:
                                                        pygame.mixer.music.load(UI_DIR + "/Voices/welcome.mp3")
                                                        pygame.mixer.music.play(0,0.0)
                                                        ns = 10
                                                        time.sleep(3)
                                                        pygame.quit()
                                                        sys.exit(0)
                                                        #commande pour quitter pygame > lancer startx > quitter python (arrêter le service)
                                              if event.type == pygame.KEYDOWN and event.key == pygame.K_n:
                                                        pygame.mixer.music.load(UI_DIR + "/Voices/valid.mp3")
                                                        pygame.mixer.music.play(0,0.0)
                                                        ns = 10
                                        ns += 0.5
                                        time.sleep(0.5)
                                if ns < 10:
                                        pygame.mixer.music.load(UI_DIR + "/Voices/alert.mp3")
                                        pygame.mixer.music.play(0,0.0)
                                        
                #time.sleep(10)
                GPIO.output(13,1)
                GPIO.output(11,1)
                time.sleep(0.8)
                GPIO.output(13,0)
                GPIO.output(11,0)
                time.sleep(0.3)
                if buttonstate!= 0 :  
                        valid=1
                     
def load_param():
        if not os.path.exists(fileparam):
                f_param = open(fileparam,'w')
                f_param.write("0")#initialise le nombre de capture effectuées à 0
                f_param.close()
        f_param = open(fileparam,'r')
        capture_amt = f_param.read()
        f_param.close()
        return (capture_amt)

def load_session():
        if not os.path.exists(filesession):
                f_param = open(filesession,'w')
                f_param.write("NO_SESSION")#initialise le nom de session 
                f_param.close()
        f_param = open(filesession,'r')
        current_session = f_param.readline()
        f_param.close()
        path = str(capture_dir) + str(current_session)
        if not os.path.exists(path):
            current_session = "NO_SESSION"
        return (current_session)

def load_para_session(filesession):
    filetxt = str(filesession) + "/"+ "session_para"
    f = open(filetxt,'r')
    ncode = f.readline()
    check_para = f.readline()
    ncode = ncode[0]
    check_para=check_para[0:(len(check_para)-1)]
    f.close()
    return(ncode, check_para)

def mkdir_with_mode(directory, mode):
  if not os.path.isdir(directory):
    oldmask = os.umask(000)
    os.makedirs(directory, mode)
    os.umask(oldmask)

def create_directories():
        if not os.path.exists(capture_dir):
                os.makedirs(capture_dir, mode=0777)
        if not os.path.exists(data_csv):
                dh =  time.strftime('%d-%m-%y %H:%M:%S', time.localtime())
                data = open(data_csv, "wb")
                data_writer = csv.writer(data)
                data_writer.writerow(["Time","Capture_Number","IDs","Message"])
                data.close()

def save_param(capture_amt):
        f_param = open(fileparam,'w')
        f_param.write(str(capture_amt))
        f_param.close()

def save_session(session_name):
        f_param = open(filesession,'w')
        f_param.write(str(session_name))
        f_param.close()

def save_para_session(dir_session, ncode, check_para):
    lines = [str(ncode),"\n",str(check_para),"\n"]
    filetxt = str(dir_session) + "/" +"session_para"
    f = open(filetxt,'w')
    f.writelines(lines)
    f.close()

def capture_amt_incrmt(capture_amt):
        capture_amt= int(capture_amt)
        if capture_amt == 99999 : #rénitialise le nombre de capture après 100 000 captures effectués soit plus de 300 000 épis 
                capture_amt = 0
        else:
                capture_amt +=1
        return(capture_amt)

def write_log(fid, capture_amt,task):

        if task == 0:
                dh =  time.strftime('%d-%m-%y %H:%M:%S', time.localtime())
                
                filename = capture_dir + 'log' + fid + ".txt"
                f_log= open(filename,'a')
                log = "Capture Number " + str(capture_amt) + " File_IDs " + str(fid) + " " + dh + "\n"
                f_log.write(log)
                f_log.close()
                data = open(data_csv, "wb")
                data_writer = csv.writer(data)
                data_writer.writerow([dh,capture_amt,fid,"Capture start"])
                data.close()
                
        if task == 1:
                filename = capture_dir + 'log' + fid + ".txt"
                f_log= open(filename,'a')
                log = "Capture " + str(capture_amt) +" complete File_IDs " + str(fid) + "\n"
                f_log.write(log)
                f_log.close()
                dh =  time.strftime('%d-%m-%y %H:%M:%S', time.localtime())
                data = open(data_csv, "wb")
                data_writer = csv.writer(data)
                data_writer.writerow([dh,capture_amt,fid,"Capture done"])
                data.close()
       
def check_precapture(output1, output2, ncode, ear_argmt_C1, ear_argmt_C2):
        global buttonstate
        capture_state = 1
        n_capt = [1,1]#camera de gauche, camera de droite >>> numero de répétition de capture avec le meme ID pour la camera 1 et 2
        n_cam = 2 #nb de camera potentiel
        if ncode ==1:#Si UNICODE
            if len(ear_argmt_C1)!=0 and len(ear_argmt_C2)!=0: #si les deux liste ne sont pas vide (= qu'il y a des epis sous les deux caméra)
                n_capt = [1,2]
        if len(ear_argmt_C1)==0 and len(ear_argmt_C2)!=0: #si aucun épis sous la camera de gauche
                n_capt = [0,1]
                n_cam = 1
        if len(ear_argmt_C1)!=0 and len(ear_argmt_C2)==0: #si aucun épis sous la camera de droite
                n_capt = [1,0]
                n_cam = 1
        ls_output = [output1, output2]
        ls_ID = [list_ID_filter_C1, list_ID_filter_C2]
        if ncode >1:
            i = 0
            for o in ls_output :
                prefile = capture_dir + session_name + "/V1" + o
                if os.path.exists(prefile):
                        if capture_state == 0 :
                            break
                        pygame.mixer.music.load(UI_DIR + "/Voices/already_used.mp3")
                        pygame.mixer.music.play(0,0.0)  
                        fake_ls_ID = "Camera" + str(i+1) + ":" + str(ls_ID[i])
                        display_cmd(w, h, "id", fake_ls_ID,255)
                        validation ()
                        #buttonstate="GB"
                        if buttonstate=="GB":
                                buttonstate=0       
                                response = 'old files erased by user'
                                #capture_state = 1
                        if buttonstate=="RB":
                                buttonstate=0
                                response = 'capture aborted by user'
                                capture_state = 0                               
                        text = "Cam" + str(i+1)+ ":" + '"' + o[2:len(o)-5] + '" Sequence_ID already used: ' + response 
                        display_info(w, h, text , 'red')
                i = i+1
                        
                
        if ncode == 1:
            i = 0
            rep = 1 # point de départ pour rechercher le numéro de la dernière rèp
            prefile = capture_dir + session_name + "/V1" + str(rep) + output1    
            if os.path.exists(prefile): #Si l'ID a déjà été utilié une fois
                pygame.mixer.music.load(UI_DIR + "/Voices/already_used.mp3")
                pygame.mixer.music.play(0,0.0)  
                check =1
                while check ==1: # Détermine la dernière répétition
                    #print prefile
                    if os.path.exists(prefile):                                        
                            rep = rep + 1
                            prefile = capture_dir + session_name + "/V1" + str(rep) + output1
                    else :
                            check = 0            
                display_cmd(w, h, "id_unik_code", ls_ID[i],255) #!!!!!!!!!!!!!!! ls_ID i
                validation_all() # Demande si il faut continuer ou écraser
                #print buttonstate
                if buttonstate=="GB": #Continuer
                        buttonstate=0       
                        #response = 'capture continues with a same ID: NEW REP START=' + str(rep)                       
                        if len(ear_argmt_C1)!=0 and len(ear_argmt_C2)!=0: #si les deux liste ne sont pas vide (= qu'il y a des epis sous les deux caméra)
                                n_capt = [rep,rep+1]   
                                response = 'EB continues with a same ID: REP(Cam1)=' + str(n_capt[0]) + ' REP(Cam2)=' + str(n_capt[1])
                        if len(ear_argmt_C1)==0 and len(ear_argmt_C2)!=0: #si aucun épis sous la camera de gauche
                                n_capt = [0,rep]
                                response = 'EB continues with a same ID: REP(Cam2)=' + str(n_capt[1])                               
                        if len(ear_argmt_C1)!=0 and len(ear_argmt_C2)==0: #si aucun épis sous la camera de droite
                                n_capt = [rep,0]
                                response = 'EB continues with a same ID: REP(Cam1)=' + str(n_capt[0]) 
                        #capture_state = 1
                if buttonstate=="RB": #Ecraser
                        buttonstate=0
                        check_erase = 0
                        while check_erase == 0: 
                            display_cmd(w, h, "rep_nb_unicode", ls_ID[i],255)
                            validation_all()#Demande si il faut ecraser les 3 ou 6 derniers épis    
                            if rep ==2 and buttonstate == "RB" : #Permet d'éviter une erreur si lutilisateur choisi decraser 6 epis alors que seulement 3 ont été capturés
                                buttonstate = 0
                            if buttonstate=="GB": #Ecraser les 3 derniers épis
                                    buttonstate=0 
                                    rep = rep - 1 #On recule donc d'une photo
                                    if len(ear_argmt_C1)!=0 and len(ear_argmt_C2)!=0: #si les deux liste ne sont pas vide (= qu'il y a des epis sous les deux caméra)
                                            n_capt = [rep,rep+1]                                        
                                    if len(ear_argmt_C1)==0 and len(ear_argmt_C2)!=0: #si aucun épis sous la camera de gauche
                                            n_capt = [0,rep]
                                            #n_cam = 1
                                    if len(ear_argmt_C1)!=0 and len(ear_argmt_C2)==0: #si aucun épis sous la camera de droite
                                            n_capt = [rep,0]
                                            #n_cam = 1
                                    response = 'old files erased by user: REP=' + str(rep)
                                    #capture_state = 1
                                    check_erase = 1
                            if buttonstate=="RB": #Ecraser les 6 derniers epis
                                    buttonstate=0
                                    rep = rep - 2# On recule donc de 2 photos
                                    if len(ear_argmt_C1)!=0 and len(ear_argmt_C2)!=0: #si les deux liste ne sont pas vide (= qu'il y a des epis sous les deux caméra)
                                            n_capt = [rep,rep+1]
                                            response = 'old files erased by user: REP(Cam1)=' + str(n_capt[0]) + ' REP(Cam2)=' + str(n_capt[1])
                                            #capture_state = 1
                                            check_erase = 1
                                    if len(ear_argmt_C1)==0 or len(ear_argmt_C2)==0: #si aucun épis sous la camera de gauche
                                        #Erreur retour pas possible d'écraser 2 photos si il n'ya que 3 épis
                                        pygame.mixer.music.load(UI_DIR + "/Voices/already_used.mp3")
                                        pygame.mixer.music.play(0,0.0)  
                            if buttonstate=="BB":
                                    buttonstate=0
                                    response = 'capture aborted by user'
                                    capture_state = 0
                                    check_erase = 1                       
                if buttonstate=="BB":
                        buttonstate=0
                        response = 'capture aborted by user'
                        capture_state = 0
                text = '"' + output1[2:len(output1)-5] + '" ID_Code already used: ' + response
                display_info(w, h, text , 'red')   
        return (capture_state,n_capt)

def display_cmd(w, h, type_cmd, list_ID_filter, cmd_a):
        winfo = w/3#w/2
        xinfo = int((float(w)/3)*2)
        yinfo = mar + (h-mar)*0.5#mar+71 + 2*(h-mar-105)/5
        wait_time = 5
        
        filename = UI_DIR + "/PNG/error.png"
        img_error = pygame.image.load(filename).convert_alpha()
        wi, hi = img_error.get_rect().size           
        y = mar+80
        h_rec = h-31 - y
        ratio = float(h_rec)/hi
        w_img = wi *1#0.7
        h_img = hi *1#0.7
        x = xinfo + winfo/2 - w_img/2
        pygame.gfxdraw.box(screen, (xinfo+22,mar+2,winfo-64,57),[250,250,250])
        cmd_bck = pygame.Surface((int(winfo-64),int(h-mar-102)))# a check
        cmd_bck = cmd_bck.convert()
        cmd_bck.fill((250,250,250))
        cmd_bck.set_alpha(int(cmd_a))
        screen.blit(cmd_bck, (int(xinfo)+22,mar+71)) #a check
        pygame.display.flip()
        
        if type_cmd == "capture":
                display_hd(w,h)
                display_3_switch("Options", "Session", "Acquisition")
                pygame.display.flip()
                
        if type_cmd == "id":
                display_2_switch("Ecraser les anciens fichiers", "Annuler")
                text_draw("Sequence d'IDs existante dans la session " ,255,0,0, xinfo + winfo/2 , mar+5 + 30 ,30, screen, 'Sans')
                text_draw_ID(list_ID_filter ,255,0,0, xinfo + winfo/2 , mar+5 + 100 ,25, screen, 'Sans')
                pygame.display.flip()

        if type_cmd == "id_unik_code":
                display_3_switch("Annuler", "Continuer avec cet ID", "Ecraser les anciens fichiers")
                text_draw("ID_Code existant dans la session " ,255,0,0, xinfo + winfo/2 , mar+5 + 30 ,30, screen, 'Sans')
                pygame.display.flip()

        if type_cmd == "rep_nb_unicode":
                display_3_switch("Annuler", "Ecraser la derniere REP", "Ecraser les 2 dernieres REP")
                text_draw("ID_Code existant dans la session " ,255,0,0, xinfo + winfo/2 , mar+5 + 30 ,20, screen, 'Sans')
                text_draw_bold_italic("une REP = une Camera" ,255,0,0, xinfo + winfo/2 , mar+5 + h*0.15 ,20, screen, 'Sans')
                text_draw_bold_italic("Camera 1 = REP n" ,255,0,0, xinfo + winfo/2 , mar+5 + h*0.18,20, screen, 'Sans')
                text_draw_bold_italic("Camera 2 = REP n+1 si deux cameras" ,255,0,0, xinfo + winfo/2 , mar+5 + h*0.21 ,20, screen, 'Sans')
                text_draw_bold_italic("Camera 2 = REP n si une camera" ,255,0,0, xinfo + winfo/2 , mar+5 + h*0.24 ,20, screen, 'Sans')
                pygame.display.flip()
                        
        if type_cmd == "check_id":
                display_2_switch("Oui", "Non")
                text_draw("L'identification est-elle correcte ?" ,20,20,20, xinfo + winfo/2 , mar+5 + 30 ,30, screen, 'Sans')
                pygame.display.flip()
                
        if type_cmd == "check_manu":
                wear = int((w/3)*2)
                im = pygame.image.load(UI_DIR + "/PNG/manual_entry_valid.png").convert_alpha()
                w_set = im.get_rect().size[0]
                h_set = im.get_rect().size[1]     
                screen.blit(im, (w/2+((wear-w_set)/2)-10,mar + ((h-mar-h_set)/2)))
                
                ls_bt = ['g', 'r']
                for b in ls_bt :
                        if b == 'g' :
                                pos = -int(h*0.05)
                                col1 = [0,200,0]
                                col2 = [0,230,0]
                                #text = "Yes"
                        if b == 'r' :
                                pos = int(h*0.15)
                                col1 = [230,0,0]
                                col2 = [255,50,50]
                                #text = "No"
                        y = int(h/2) #mar+71 + 2*(h-mar-105)/4
                        pygame.gfxdraw.filled_circle(screen, xinfo + (winfo/2)-10,y + pos , 40, [200,200,200]) #(surface, x, y, r, color)
                        pygame.gfxdraw.aacircle(screen, xinfo + (winfo/2)-10  , y + pos , 40, [100,100,100]) #(surface, x, y, r, color)
                        pygame.gfxdraw.filled_circle(screen, xinfo + (winfo/2)-10  , y + pos , 28, col2) 
                        pygame.gfxdraw.aacircle(screen, xinfo + (winfo/2)-10  , y + pos , 28, col1)
                        pygame.gfxdraw.filled_circle(screen, xinfo + (winfo/2)-10  , y + pos , 22, [200,200,200]) #(surface, x, y, r, color)
                        pygame.gfxdraw.aacircle(screen, xinfo + (winfo/2)-10   , y + pos , 22, col1) #(surface, x, y, r, color)
                pygame.display.flip()
                
        if type_cmd == "wrg_nb_unicode":

                screen.blit(img_error, (x,y))
                if len(list_ID_filter) > 1:
                        text1 = "Plus qu'un seul code saisi !" # + str(list_ID_filter)#"More than one code detected : " + str(list_ID_filter)
                if len(list_ID_filter) < 1:
                        text1 = "Aucun code saisi"#"No code detected"
                text2 = "Saisir un code unique SVP"#Insert an unique code please"
                
                text_draw(text1,255,0,0, xinfo + winfo/2 , yinfo -30, 25, screen, 'Roboto Condensed')
                text_draw(text2,255,0,0, xinfo + winfo/2 , yinfo +30, 25, screen, 'Roboto Condensed')
                pygame.display.flip()
                time.sleep(wait_time)
                
        if type_cmd == "wrg_nb_multicode":
                screen.blit(img_error, (x,y))
                if len(list_ID_filter) == 0:
                        #text1 = "No code detected"
                        text1 = "Aucun code saisi"
                if len(list_ID_filter) <= 6: #3
                        #text1 = "Lack of codes" 
                        text1 = "Il manque des codes"
                #text2 = "Insert one code per ear please"
                text2 = "Saisir un code par epi SVP"
                text_draw(text1,255,0,0, xinfo + winfo/2 , yinfo -30, 25, screen, 'Roboto Condensed')
                text_draw(text2,255,0,0, xinfo + winfo/2 , yinfo +30, 25, screen, 'Roboto Condensed')
                pygame.display.flip()
                time.sleep(wait_time)
                
        if type_cmd == "wrg_nb_multicode_ear":
                screen.blit(img_error, (x,y))
                if len(list_ID_filter) == 0:
                        #text1 = "No ear detected"
                        text1 = "Aucun epi detecte"
                if len(list_ID_filter) <= 6: #3
                        #text1 = "Lack of ears"
                        text1 = "Il manque des epis" 
                #text2 = "Insert one ear per code please"
                text2 = "Presenter un epi par code SVP"
                text_draw(text1,255,0,0, xinfo + winfo/2 , yinfo -30, 25, screen, 'Roboto Condensed')
                text_draw(text2,255,0,0, xinfo + winfo/2 , yinfo +30, 25, screen, 'Roboto Condensed')
                pygame.display.flip()
                time.sleep(wait_time)

        if type_cmd == "wrong_corres":
                screen.blit(img_error, (x,y))
                #text1 = "Wrong position of ears or codes"
                #text2 = "Check positions"
                text1 = "Mauvaises positions des epis ou des codes"
                text2 = "Verifier les positions"                
                text_draw(text1,255,0,0, xinfo + winfo/2 , yinfo -30, 25, screen, 'Roboto Condensed')
                text_draw(text2,255,0,0, xinfo + winfo/2 , yinfo +30, 25, screen, 'Roboto Condensed')
                pygame.display.flip()
                time.sleep(wait_time)
                
        if type_cmd == "no_ear":
                screen.blit(img_error, (x,y))
                #text1 = "No ear detected"
                #text2 = "Check the position of ears" 
                text1 = "Aucun epi detecte"
                text2 = "Verifier les positions des epis"                 
                text_draw(text1,255,0,0, xinfo + winfo/2 , yinfo -30, 25, screen, 'Roboto Condensed')
                text_draw(text2,255,0,0, xinfo + winfo/2 , yinfo +30, 25, screen, 'Roboto Condensed')
                pygame.display.flip()
                time.sleep(wait_time)

        if type_cmd == "halt":
                display_3_switch("Retour","Settings","Extinction")
                text_draw_bold_italic("Settings" ,0,170,0, xinfo + winfo/2 , mar+5 + 30 ,30, screen, 'Roboto Condensed')
                pygame.display.flip()

        if type_cmd == "settings":
                display_3_switch("Retour","Volume","Date/Heure")
                text_draw_bold_italic("Settings" ,0,170,0, xinfo + winfo/2 , mar+5 + 30 ,30, screen, 'Roboto Condensed')
                pygame.display.flip()
                
        if type_cmd == "volume_set":
                display_3_switch("Retour","+","-")
                text_draw_bold_italic("Volume" ,0,170,0, xinfo + winfo/2 , mar+5 + 30 ,30, screen, 'Roboto Condensed')
                pygame.display.flip()

def display_3_switch(txt_blue, txt_green, txt_red):
                winfo = w/3#w/2
                xinfo = int((float(w)/3)*2)
                y = mar+71 + int(1.3*(h-mar-105)/4)
                #Blue
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) , y , 20, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) , y , 20, [100,100,100]) #(surface, x, y, r, color)
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 15, [80,80,255]) 
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 15, [0,0,250])
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 12, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y,12, [0,0,250]) #(surface, x, y, r, color)
                text_draw_right(txt_blue,90,90,90, xinfo + winfo/1.5, y -12 ,25, screen, 'Roboto Condensed')
                #Green
                y = int((h/2)*1.07)		
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 40, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 40, [100,100,100]) #(surface, x, y, r, color)
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 28, [0,230,0]) 
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 28, [0,200,0])
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 22, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 22, [0,200,0]) #(surface, x, y, r, color)
                text_draw_right(txt_green,60,60,60, xinfo + winfo/1.5, y -20 ,40, screen, 'Roboto Condensed')
                #Red
                y = int((h/2)*1.45)
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 40, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 40, [100,100,100]) #(surface, x, y, r, color)
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 28, [255,50,50]) 
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 28, [230,0,0])
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 22, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 22, [230,0,0]) #(surface, x, y, r, color)
                text_draw_right(txt_red,60,60,60, xinfo + winfo/1.5, y -20 ,40, screen, 'Roboto Condensed')

def display_2_switch(txt_green, txt_red):
                winfo = w/3#w/2
                xinfo = int((float(w)/3)*2)
                y = mar+71 + int(1.3*(h-mar-105)/4)
                #Green
                y = int((h/2)*1.07)	
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 40, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 40, [100,100,100]) #(surface, x, y, r, color)
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 28, [0,230,0]) 
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 28, [0,200,0])
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 22, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 22, [0,200,0]) #(surface, x, y, r, color)
                text_draw_right(txt_green,60,60,60, xinfo + winfo/1.5, y -20 ,40, screen, 'Roboto Condensed')
                #Red
                y = int((h/2)*1.45)
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 40, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 40, [100,100,100]) #(surface, x, y, r, color)
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 28, [255,50,50]) 
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 28, [230,0,0])
                pygame.gfxdraw.filled_circle(screen, xinfo + 3*(winfo/4) ,y, 22, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, xinfo + 3*(winfo/4) ,y, 22, [230,0,0]) #(surface, x, y, r, color)
                text_draw_right(txt_red,60,60,60, xinfo + winfo/1.5, y -20 ,40, screen, 'Roboto Condensed')

def display_2_switch_session(txt_green, txt_red):
                winfo = w/3#w/2
                xinfo = int((float(w)/3)*2)
                y = mar+71 + int(1.3*(h-mar-105)/4)
                #Green
                y = int((h/2)*1.07)
                posx = int((w*0.78)) 			
                pygame.gfxdraw.filled_circle(screen, posx ,y, 40, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, posx ,y, 40, [100,100,100]) #(surface, x, y, r, color)
                pygame.gfxdraw.filled_circle(screen, posx ,y, 28, [0,230,0]) 
                pygame.gfxdraw.aacircle(screen, posx ,y, 28, [0,200,0])
                pygame.gfxdraw.filled_circle(screen, posx ,y, 22, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, posx ,y, 22, [0,200,0]) #(surface, x, y, r, color)
                text_draw_right(txt_green,60,60,60, xinfo + winfo/1.6, y -20 ,40, screen, 'Roboto Condensed')
                #Red
                y = int((h/2)*1.45)
                pygame.gfxdraw.filled_circle(screen, posx ,y, 40, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, posx ,y, 40, [100,100,100]) #(surface, x, y, r, color)
                pygame.gfxdraw.filled_circle(screen, posx ,y, 28, [255,50,50]) 
                pygame.gfxdraw.aacircle(screen, posx ,y, 28, [230,0,0])
                pygame.gfxdraw.filled_circle(screen, posx ,y, 22, [200,200,200]) #(surface, x, y, r, color)
                pygame.gfxdraw.aacircle(screen, posx ,y, 22, [230,0,0]) #(surface, x, y, r, color)
                text_draw_right(txt_red,60,60,60, xinfo + winfo/1.6, y -20 ,40, screen, 'Roboto Condensed')
                
def display_progress(w, h, typ, step):
        winfo = w/3
        xinfo = int((w/3)*2)
        pygame.gfxdraw.box(screen, (xinfo+22,mar+2,winfo-64,57),[250,250,250])
        if typ =='ear':
                maxstep = 7 # 6 faces + transfert
                pygame.gfxdraw.box(screen, (xinfo+23,mar+2,(int(winfo-64)/maxstep)*step,18),[255-int(255/maxstep)*step,255-(10*step),255-int(255/maxstep)*step])                
                text_draw("Acquisition en cours ("+str(int((100/maxstep)*step)) +"%)" ,0,170,0, xinfo + winfo/2 , mar+5 + 30 ,25, screen, 'Sans')
        if typ =='code':
                maxstep = 3
                pygame.gfxdraw.box(screen, (xinfo+23,mar+2,(int(winfo-66)/maxstep)*step,18),[255-63*step,255-(15*step),255-63*step])
                text_draw("Detection en cours ("+str(int((100/maxstep)*step)) +"%)" ,0,170,0, xinfo + winfo/2 , mar+5 + 30 ,25, screen, 'Sans')
        pygame.display.flip()

def display_hd(w, h): 
        winfo = w/3
        #winfo =w/2
        xinfo = (w/3)*2
        
        statvfs = os.statvfs(drive_dir)
        hd_size = statvfs.f_frsize * statvfs.f_blocks     # Size of filesystem in bytes
        free_size = statvfs.f_frsize * statvfs.f_bfree      # Actual number of free bytes
        pct_used = (float(hd_size- free_size) / int(hd_size))* 100
        maxstep = 100
        step = int(pct_used)
        xbox = xinfo+25 #int((w/3)*2+(winfo*0.0337))
        wbox = float(winfo-69)#int(winfo*0.87)
        ybox = mar+2#int(h*0.081) # = mar+2 = 60+2
        hbox = 18
        pygame.gfxdraw.box(screen, (xbox,ybox,wbox,57),[250,250,250])
        pygame.gfxdraw.box(screen, (xbox, ybox,(float(wbox)/maxstep)*step,hbox),[0,170,0])
        pygame.gfxdraw.rectangle(screen, (xbox, ybox,(float(wbox)/100)*100,hbox),[0,170,0])
        
        text_draw("Utilisation disque externe: "+str(round(pct_used,3)) +"%" ,0,170,0, xbox + (winfo-mar)/2 , mar+5 + 30 ,25, screen, 'Roboto Condensed')
        pygame.display.flip()

def display_volume(w, h, volume):
        winfo = w/3
        xinfo = int((float(w)/3)*2)
        y = int(h*0.6)
        w_b = (winfo - 66 )*0.55
        h_b = 50
        pygame.gfxdraw.box(screen, (xinfo+int(winfo*0.1), y,w_b,h_b),[250,250,250])
        step = volume * 100 
        maxstep = 100
        pygame.gfxdraw.box(screen, (xinfo+int(winfo*0.1), y,(float(w_b/100)*step),h_b),[0,170,0])
        pygame.gfxdraw.rectangle(screen, (xinfo+int(winfo*0.1),y,(float(w_b/100)*100),h_b),[0,170,0])
        pygame.display.flip()

def display_c_amnt(w, h, c_amnt):          
        r,g,b = (0,170,0)
        x = ((w/3)*2+20) + ((w/3-60)/4)*3
        y = mar*0.45
        pygame.gfxdraw.box(screen, ((w/3)*2+20+2 + (w/3-60-2)/2,mar*0.1+1,(w/3-60)/2-2,mar*0.8-2),[250,250,250])
        text_draw_bold_italic("NB d'acquisitions",r,g,b, x,y-7 ,20, screen, 'Roboto Condensed')
        text_draw(str(c_amnt) ,r,g,b, x,y+15 ,22, screen, 'Roboto Condensed')
        pygame.display.flip()

def display_session(w, h, session_name, ncode, check_para):
        r,g,b = (0,170,0)
        x = int(w*0.3485)
        y = mar/2
        wsess= w*0.487#int(((w/3)*2)*0.7)
        ncode = str(ncode)
        check_para = str(check_para)
        if ncode == "1":
            mode = "Unicode"
        else:
            mode = "Multicode"
        if check_para == "True":
            verif = "ON"
        else : 
            verif = "OFF"
        posx = w*0.45 #0.454
        pygame.gfxdraw.box(screen, (x-120,5,240,50),[250,250,250])
        pygame.gfxdraw.rectangle(screen, (w*0.18,mar*0.1,wsess,mar*0.8),[0,170,0])
        pygame.gfxdraw.rectangle(screen, (posx,mar*0.1,w*0.216/2,mar*0.8),[0,170,0])
        pygame.gfxdraw.box(screen, (w*0.18,mar*0.1,82,22),[0,170,0])
        pygame.gfxdraw.rectangle(screen, (posx,mar*0.1,w*0.217,mar*0.4),[0,170,0])
        text_draw_left_bold_italic("Session",250,250,250, w*0.185,(h*0.008),24, screen, 'Roboto Condensed')
        text_draw_left_bold(str(session_name) ,50,50,50, w*0.185, (h*0.0315) ,22, screen, 'Roboto Condensed')
        text_draw_bold_italic("ID Mode",r,g,b, posx+(w*0.214/2)/2 ,(mar*0.3),22, screen, 'Roboto Condensed')
        text_draw_bold_italic("Check ID",r,g,b, posx+(w*0.214/4)*3 ,(mar*0.3),22, screen, 'Roboto Condensed')
        text_draw(str(mode),50,50,50, posx+(w*0.214/2)/2 ,(mar*0.7),22, screen, 'Roboto Condensed')
        text_draw(str(verif),50,50,50, posx+(w*0.214/4)*3 ,(mar*0.7),22, screen, 'Roboto Condensed')
        pygame.display.flip()


def time_manual_def(w,h,step):
    global buttonstate
    set_time_state=0
    
    logo = pygame.image.load(UI_DIR + "/PNG/small_logo.png").convert_alpha()
    im_hour = pygame.image.load(UI_DIR + "/PNG/heure_1920.png").convert_alpha()
    w_im = im_hour.get_rect().size[0]
    h_im = im_hour.get_rect().size[1]
    pos_logo = (50,7)

    
    while set_time_state==0:
        x = (w/2)
        y = (h/3)
        r,g,b = (0,170,0)
        
        if step == "start":
            screen.blit(im_hour, ((w-w_im)/2,(h-h_im)/2))
            screen.blit(logo, pos_logo)   
            pi_time = time.strftime('%d/%m/%Y %H:%M', time.localtime()) 
        
            text_draw("La date et l'heure sont-elles correctes ?",50,50,50, x,y-60 ,60, screen, 'Roboto Condensed') 
            text_draw(pi_time,r,g,b, x,y ,60, screen, 'Roboto Condensed')     
        
            display_2_switch("Oui", "Non")
            pygame.display.flip()
            validation()
        else :
            buttonstate = "RB"
       
        if buttonstate=="GB":#Poursuivre 
            set_time_state=1
            buttonstate = 0
        if buttonstate=="RB":#Modifier l'heure
            buttonstate = 0
            screen.blit(im_hour, ((w-w_im)/2,(h-h_im)/2))
            screen.blit(logo, pos_logo)   
            
            #Parametre d'affichage de la boite de saisie
            r,g,b= 250,250,250
            c =[50,50,50]
            w_rec = int(w_im*0.41)
            x = int((w-w_im)/2 + (w_im-w_rec)/2)
            y = h_im*0.5
            
            text_decal = 20
            pygame.gfxdraw.box(screen, (x,y,w_rec,60),c)
            text_draw_left_bold ("Saisir la date et l'heure sous ce format ->25/12/2020 20:55",r,g,b,x+text_decal,y+text_decal,40, screen, 'Roboto Condensed')
            pygame.display.flip()

            current_string = []
            str_temp =[]
            while True:
                try:   
                    inkey, uc = get_key()
                    character = uc.encode('utf8')
                except :
                    print "PB Clavier"
                
                if inkey == K_BACKSPACE:
                    current_string = current_string[0:-1]
                elif inkey == K_SPACE: 
                    current_string.append(" ")
                elif inkey == K_RETURN or inkey == K_KP_ENTER:
                    #print "fin de saisi"
                    break 
                elif str(character) in ls_uc_date:
                    keypress = str(character)
                    current_string.append(keypress)

                str_temp = string.join(current_string,"")
                pygame.gfxdraw.box(screen, (x,y,w_rec,60),c)
                text_draw_left_bold (str(str_temp),r,g,b,x+text_decal,y+text_decal,45, screen, 'Roboto Condensed')
                pygame.display.flip() 
                
            manu_time = str_temp
            c =[ 0,170,0]
            pygame.gfxdraw.box(screen, (x,y,w_rec,60),c)
            text_draw_left_bold (str(manu_time),r,g,b,x+text_decal,y+text_decal,45, screen, 'Roboto Condensed') 
            pygame.display.flip()            
            
            if len(manu_time)==16 and manu_time[2] =="/" and manu_time[5] =="/" and manu_time[10] ==" " and manu_time[13] ==":": 
                time_format = manu_time[6:10] + "-" + manu_time[3:5] + "-" + manu_time[0:2] + " " + manu_time[11:13] + ":" + manu_time[14:16] +":00"
                cmd = 'sudo hwclock --set --date="' + time_format +'"' #Commande pour set la RTC #sudo hwclock --set --date="2020-07-25 12:46:00"
                subprocess.call(cmd, shell=True)
                cmd = "sudo hwclock -s" #Commande pour set le RPi from RTC
                subprocess.call(cmd, shell=True)
                set_time_state=1
            else:
                print ("Format Date/Heure Incorrect !!!!!")
            
        

def display_time(w, h):        
        Heure = time.strftime('%H:%M', time.localtime())
        Date = time.strftime('%d/%m/%Y', time.localtime())       
        r,g,b = (0,170,0)
        x = ((w/3)*2+20) + (w/3-60)/6#int(w*0.75)#int(w*0.3485)#w/2
        y = mar/2
        pygame.gfxdraw.box(screen, ((w/3)*2+20+1,mar*0.1+1,(w/3-60)/2-2,mar*0.8-2),[250,250,250]) 
        text_draw(Heure,r,g,b, x,y-9 ,35, screen, 'Roboto Condensed')
        text_draw(Date,r,g,b, x,y+15 ,20, screen, 'Roboto Condensed')

        cmd = "echo $(cat /sys/bus/i2c/devices/1-0068/hwmon/hwmon1/temp1_input|awk '{print $0}')"
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        temp_rtc = p.communicate()[0]    
        temp_rtc = float(temp_rtc[0:4])/100
        cmd = "/opt/vc/bin/vcgencmd measure_temp"
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        temp_rpi= p.communicate()[0]    
        temp_rpi = float(temp_rpi[5:9])
        r,g,b = (0,170,0)
        x1 = ((w/3)*2+20) + ((w/3-60)/5.5)*2
        x2 = ((w/3)*2+20) + ((w/3-60)/5.5)*2
        y = mar/2
        text_draw("CPU: " + str(round(temp_rpi,1)) + u"\u2103",r,g,b, x1,y/1.6 ,25, screen, 'Roboto Condensed')
        text_draw("Earbox: " + str(round(temp_rtc,1)) + u"\u2103",r,g,b, x2,y*1.4 ,25, screen, 'Roboto Condensed')
        pygame.display.flip()
         
def display_info(w, h, text, color):
        Heure = time.strftime('%H:%M', time.localtime())
        text = Heure + "-" + text
        #near = 3
        winfo = w/3
        xinfo = int((w/3)*2)
        pygame.gfxdraw.box(screen, (xinfo+22,mar+71,winfo-64,h-mar-102),[250,250,250])
        pygame.gfxdraw.box(screen, (xinfo+22,mar+2,winfo-64,57),[250,250,250])
        ls_info.append(text)
        ls_info_col.append(color)
        while len (ls_info) > 60: #initialement 40 pour le petit ecran
                del ls_info[0]
                del ls_info_col[0]
        n= mar + 60 + 13 + 2
        i2 = 0
        for i in ls_info:
                col = ls_info_col[i2]
                if col == "green":
                         r,g,b = (0,200,0)
                if col == "red":
                         r,g,b = (250,50,0)
                if col == "grey":
                        r,g,b = (100,200,150)
                text_draw_left (i,r,g,b, xinfo + 25 ,n ,13, screen, 'Sans')        
                n += 15
                i2 += 1 
        pygame.display.flip()

def photo_sequence(output1, output2, n_capt): 
        exif_distant = write_exif("distant", session_name)
        exif_local = write_exif("local", session_name)
    #Visible
        led_visi_ctrl(1,1)
        time.sleep(0.1)#Mauguio =0.1
        if n_capt[0]!=0: #Si il y a des épis sous la camera de gauche 1
            filepath = capture_dir_distant + "/V" + output1
            stdout = take_photo_distant("capture", filepath, "visi", exif_distant)
        if n_capt[1]!=0: #Si il y a des épis sous la camera de droite 2
            filepath = capture_dir + session_name + "/V" + output2
            take_photo_local("capture", filepath, "visi", exif_local)
        if n_capt[0]!=0 and stdout.channel.recv_exit_status() != 0:
                print "Error : Raspistill Error"

    #IR
        led_visi_ctrl(1,0)
        led_ir_ctrl(1, 1)
         
        time.sleep(0.2)#Muaguio =0.2
        if n_capt[0]!=0: #Si il y a des épis sous la camera de gauche
            filepath = capture_dir_distant + "/I" + output1
            stdout = take_photo_distant("capture", filepath, "ir", exif_distant)   
        if n_capt[1]!=0: #Si il y a des épis sous la camera de droite
            filepath = capture_dir + session_name + "/I" + output2
            take_photo_local("capture", filepath, "ir", exif_local)
        if n_capt[0]!=0 and stdout.channel.recv_exit_status() != 0:
                print "Error : Raspistill Error"
        led_ir_ctrl(0, 0)

def photo_transfer(filename):
    filepath_campi = capture_dir_distant + filename 
    filepath_earboxpi = capture_dir + session_name + "/" + filename 
    cmd="sudo sshpass -p " +DISTANT_PWD+ " scp "  + filepath_campi  + " " +LOCAL_USER+"@earboxpi.local:" + filepath_earboxpi

    ftp_client=client.open_sftp()
    ftp_client.get(filepath_campi,filepath_earboxpi)
    ftp_client.close()
    state = 0
    while state ==0:
        try:
            im = Image.open(filepath_earboxpi)
            state =1
        except:
            #print 'waiting for copy...'
            time.sleep(0.2)
    time.sleep(0.3)
    stdin,stout,stderr = client.exec_command("sudo rm " + filepath_campi)
    time.sleep(0.5)
       
def ear_capture(l_ID, l_ID_C1, l_ID_C2,ear_argmt_C1,ear_argmt_C2, capture_amt, ncode): 
        if ncode ==1 :
            l_ID_C1 = l_ID
            l_ID_C2 = l_ID
        text = 'Capture ' + str(capture_amt)+ ' begins, please wait...'
        display_info(w, h, text , 'green')
        text = 'ID CAM1: ' + str(l_ID_C1)
        display_info(w, h, text , 'grey')
        text = 'ID CAM2: ' + str(l_ID_C2)
        display_info(w, h, text , 'grey')
        start = datetime.datetime.now()
        fid = ""
        #création de nom de fichier "basique" en fonction des barcodes
        for i in l_ID :
                fid = fid + "@"  + str(i) 
        #write_log(fid, capture_amt ,0)
        fid1 = ""
        for i in l_ID_C1 :
                fid1 = fid1 + "@"  + str(i) 
        fid2 = ""
        for i in l_ID_C2 :
                fid2 = fid2 + "@"  + str(i) 
        fidi1 = fid1 +".jpeg"
        fidi2 = fid2 +".jpeg"
        if ncode == 1: #Si UNICODE tout le monde a le même code initial
                fidi1 = "U" + fidi1
                fidi2 = "U" + fidi2
        else:
                fidi1 = "xM" + fidi1
                fidi2 = "xM" + fidi2        
        capture_state, ncapt = check_precapture(fidi1, fidi2, ncode, ear_argmt_C1, ear_argmt_C2)#verifie la présence de fichiers identiques
        start = datetime.datetime.now()
        if ncode== 1: #Si Mode UNICODE insert le numéro de répétition de capture avec le même ID pour chaque Caméra de façon indépendante / Il ny pas de répition en MULTICODE donc pas besoin d'insérer ce chiffre
                fidi1 = str(ncapt[0]) + fidi1
                fidi2 = str(ncapt[1]) + fidi2
        if capture_state ==1 :
                capture_amt = capture_amt_incrmt(capture_amt)   
                ##Boucle à 2 essais pour séquence photo, si pb (= pas de photo sur HDD) la Box s'éteint
                n_try = 0
                while n_try<2 :
                    ls_ext = []
                    #démarrage de la séquence de capture d'image        
                    delay = 1 #pour être sur que l'épi ne tourne plus lors de la première photo (visible)
                    #Initialise l'arduino pour une séquence d'acquisition (rotation + photos)
                    GPIO.output(pinING,1)
                    time.sleep(0.02)
                    GPIO.output(pinING,0)
                    
                    ##########################ROTATION ET PHOTOS
                    threads = []
                    for p in range(1,7): #Boucle pour le nombre de photo
                        output1 = str(p) +fidi1
                        output2 = str(p) +fidi2
                        display_progress(w, h, 'ear', p-1)
                        #print "PS start"
                        photo_sequence(output1, output2, ncapt)
                        #print "PS done"                    
                        ############################################
                        if len(ear_argmt_C1) != 0 :#Si il y a des épis sous la camera de gauche
                            filename_RGB = "V" + output1
                            filename_IR = "I" + output1
                            thread = Copythread(client, filename_RGB, filename_IR, capture_dir, capture_dir_distant, session_name)
                            threads.append(thread)
                            thread.start()
                        ####################################                                   
                        if p <= 5: #pour les 5première photos déclenche une rotation à la fin de la capture
                            GPIO.output(pinROT,1)
                            time.sleep(0.02)
                            GPIO.output(pinROT,0)
                            time.sleep(delay)                        
                    ##############################################                   
                    end= datetime.datetime.now()
                    dif = end - start
                    text = 'Capture ' + str(capture_amt)+ ' done in ' + str(dif.seconds) +'s'
                    display_info(w, h, text , 'green')                
                    #Copie des photos CAM1 et REMOVE!!!!!!!!!!!!
                    start = datetime.datetime.now()
                    display_progress(w, h,'ear', 6)   
                    for thread in threads:
                                thread.join()
                    ###Check si les photos sont toutes stockées sur le HDD
                    if check_files_after_sequence(capture_dir, session_name, ear_argmt_C1, output1[1:], ear_argmt_C2, output2[1:]) != True:
                        time.sleep(3)
                        if check_files_after_sequence(capture_dir, session_name, ear_argmt_C1, output1[1:], ear_argmt_C2, output2[1:]) != True:
                            n_try = n_try +1
                        else:
                            break
                    else:
                        break
                    
                    if n_try==2: #Si a y eu 2 essais infructueux la box s'arrête
                        pygame.mixer.music.load(UI_DIR + "/Voices/no_hdd.mp3")
                        pygame.mixer.music.play()
                        time.sleep(2)
                        halt_pis() 
                


                
                #fin séquence photo
                display_progress(w, h,'ear', 7)
                pygame.mixer.music.load(UI_DIR + "/Voices/capture_done2.mp3")
                pygame.mixer.music.play(0,0.0) 
                end= datetime.datetime.now()
                dif = end - start
                text = 'Copy ' + str(capture_amt)+ ' done in ' + str(dif.seconds) +'s'
                display_info(w, h, text , 'green')
              
                save_param(capture_amt)
                                
                                              

        return(capture_amt) 

def detect_nb(scan):
        l_scan = scan.size#identifie la longueur (lenght) de scan ici 50=la largeur de la photo IR
        scan[0] = 0 #insère un zero a gauche de l'image pour detecté l'épi le + à gauche de la cam1 (épi dont la vrai photo est prise par la cam2)
        scan[l_scan-1] = 0 
        ear_pos = [] #creer une liste pour enregistrer les bornes de chaque épi
        for i in range(0,l_scan-1): # pour les 50 (0 à 49) pixels de la ligne de scan
                ni = scan[i] #valeur du pixel i
                nii = scan[i+1] #valeur du pixel i+1
                if ni == 0: #si la valeur du pixel ni =0
                        if nii > 0: #et si la valeur du pixel ni+1 >0 
                                ear_pos.append(i+1)# alors tu détectes la borne gauche d'un épi > enregistre la position du pixel ni+1
                if ni >0: #si la valeur du pixel ni >0
                        if nii ==0: # et si la valeur du pixel ni+1 =0
                                ear_pos.append(i)#alors tu détectes la borne droite d'un épi > enregistre la position du pixel ni
        n_ear_detect = len(ear_pos)/2 # identifie le nombre d'épi détecté = le nombre de bornes détectées/2
        return (n_ear_detect, ear_pos)

def ear_reco(col, n_ear_detect, pos_ear_inbox, ear_pos,pos_start):
        im_col = Image.open(col) #charge la photo en visible
        wc, hc = im_col.size #identifie la taille de l'image 
        list_l_lim = [] #creer une liste des bornes gauches détectées
        list_mean = []
        ear_argmt =[] #creer la liste de la position des épis sur l'image 
        
        for e in range(1,n_ear_detect*2, 2): #pour chaque épi détecté (mais fonctionne avec le NOMBRE de bornes = 2*nb épis)
                l_lim = (ear_pos[e-1]) * 20 #calcule la borne gauche sur l'image visible dont la résolution = résolution image IR*20
                r_lim = (ear_pos[e]+1) * 20   #calcule la borne droite = premier pixel qui n'appartient pas a l'épi > pos+1
                list_l_lim.append(l_lim) #enregistre la borne gauche
                pos_mean = (l_lim+r_lim)/2
                list_mean.append(pos_mean)
                dif =  pos_mean - np.array(pos_ear_inbox) # calcule la dif entre la borne gauche de l'épi et toutes les bornes gauches potentielles
                difa = abs(dif)
                min_dif = min(difa) #recherche la différences minimal
                if min_dif <=50: # si la distance inférieure à 1/2 rouleau (~100=rouleau)
                        pos_of_ear = int(np.argwhere(difa==min_dif)) +1 #récupère la position dans la liste de la différence min pour identifier la position de l'épi sur l'image
                        pos_of_ear = pos_of_ear + (pos_start-1)                     
                        box = (int(l_lim*0.9),25,int(r_lim*1.1),hc)
                        im_ear = im_col.crop(box) #rogne l'image visible et récupère une image de l'épi
                        filename = DETECTION_DIR + "/ear" + str(int(pos_of_ear)) +".jpg" 
                        im_ear.save (filename)#enregistre l'image de l'épi
                        ear_argmt.append(pos_of_ear) #enregistre la position de l'épi sur l'image
                        im_ear.close()
        im_col.close()
        cmd = "sudo rm " + col
        subprocess.call(cmd, shell=True)
        return (ear_argmt)

def ear_detection(): 
        start= datetime.datetime.now()
        led_ignition_time =0.3
        text = 'Ears detection'
        display_info(w, h, text , 'green')
        display_progress(w, h,'code', 0)
        exif =""

        led_visi_ctrl(1, 1)
        time.sleep(led_ignition_time)# temps nécessaire pour allumage des leds

        filepathv =  DISTANT_ROOT_DIR + "/cam2_detect_visi.jpg" 

        filepathi =  DISTANT_ROOT_DIR + "/cam2_detect_ir.jpg"  
#Capture Camera 2 Visi       
        stdout = take_photo_distant_detect("detect",filepathv,"visi")
#Capture Camera 1 Visi
        filepath =  DETECTION_DIR + "/cam1_detect_visi.jpg"
        take_photo_local("detect", filepath, "visi", exif)
#Copie 1 Camera 2 Visi
        filepath_campi = DISTANT_ROOT_DIR + "/cam2_detect_visi.jpg"
        filepath_earboxpi = DETECTION_DIR + "/cam2_detect_visi.jpg"
        ftp_client=client.open_sftp()
        ftp_client.get(filepath_campi,filepath_earboxpi)
        ftp_client.close()
#IR
        display_progress(w, h,'code', 1)
        led_visi_ctrl(1, 0)
        #GPIO.output(pinR2,0)#LED IR ON
        led_ir_ctrl(1, 1)
        time.sleep(led_ignition_time)# temps nécessaire pour allumage des leds
#Capture Camera 2 IR
        
        stdout = take_photo_distant_detect("detect",filepathi,"ir")
        #print stdout
#Capture Camera 1 IR
        filepath =  DETECTION_DIR + "/cam1_detect_ir.jpg"
        take_photo_local("detect", filepath, "ir", exif)
#Copie 2 Camera 2 IR
        
        filepath_campi = DISTANT_ROOT_DIR + "/cam2_detect_ir.jpg"
        filepath_earboxpi = DETECTION_DIR + "/cam2_detect_ir.jpg"
        ftp_client=client.open_sftp()
        ftp_client.get(filepath_campi,filepath_earboxpi)
        ftp_client.close()        
        #GPIO.output(pinR2,1)#LED IR OFF
        led_ir_ctrl(0, 0)
        state =0
        while state ==0:
                try:
                        im = Image.open(DETECTION_DIR + "/cam2_detect_ir.jpg")
                        state =1
                except:
                        #print 'waiting for copy...'
                        time.sleep(0.2)

####Ouverture des photos IR et rognage
        display_progress(w, h,'code', 2)
        im_c1 = nd.imread(DETECTION_DIR + "/cam1_detect_ir.jpg", mode = 'L')#mode L = niveau de gris normalement j'ai pas affiché l'image donc je sais pas trop...
        im_c2 = nd.imread(DETECTION_DIR + "/cam2_detect_ir.jpg", mode = 'L')
        im_c1[im_c1<18]=0 # élimine le bruit de fond à la base 15 et 20 ca merde
        im_c1[im_c1>0]=255# remplie les épis > en fait non : gros coup de chatte les valeurs de bordures sont divisées par deux (255 passe a 127) ce qui permet de détecter gratos les bords de l'épi
        scan_c1 = im_c1[28,:]#récupère une ligne de scan en milieu d'image (56/2) #28
        misc.imsave(DETECTION_DIR + "/cam1_rot.jpg",im_c1)
        im_c2[im_c2<18]=0 # élimine le bruit de fond à la base 15 et 20 ca merde
        im_c2[im_c2>0]=255# remplie les épis > en fait non : gros coup de chatte les valeurs de bordures sont divisées par deux (255 passe a 127) ce qui permet de détecter gratos les bords de l'épi

        scan_c2 = im_c2[28,:]#récupère une ligne de scan en milieu d'image (56/2) #28

        misc.imsave(DETECTION_DIR + "/cam2_rot.jpg",im_c2)
        cmd = "sudo rm " + DETECTION_DIR + "/cam1_detect_ir.jpg"
        subprocess.call(cmd, shell=True)
        cmd = "sudo rm " + DETECTION_DIR + "/cam2_detect_ir.jpg"
        subprocess.call(cmd, shell=True)
        
        n_ear_detect_c1, ear_pos_c1 = detect_nb(scan_c1)
        n_ear_detect_c2, ear_pos_c2 = detect_nb(scan_c2)

        #découpe les photos des épis détectés
        col_c1= DETECTION_DIR + "/cam1_detect_visi.jpg"
        col_c2= DETECTION_DIR + "/cam2_detect_visi.jpg"

        pos_ear_inbox_c1 = [260,500,750]#[115,235,360] #position potentielle des épis
        pos_ear_inbox_c2 = [230,470,720]#[260,480,700]#[130,240,350]
        pos_start1 = 4
        pos_start2 = 1
        ear_argmt_c1 = ear_reco(col_c1, n_ear_detect_c1, pos_ear_inbox_c1, ear_pos_c1, pos_start1)
        ear_argmt_c2 = ear_reco(col_c2, n_ear_detect_c2, pos_ear_inbox_c2, ear_pos_c2, pos_start2)
        ear_argmt=[]
        for e in range(0,len(ear_argmt_c2), 1):
                ear_argmt.append(ear_argmt_c2[e])
        for e in range(0,len(ear_argmt_c1), 1):
                ear_argmt.append(ear_argmt_c1[e])
        
        stdin,stout,stderr = client.exec_command('sudo rm ' + filepathv)
        stdin,stout,stderr = client.exec_command('sudo rm ' + filepathi)
        end= datetime.datetime.now()
        duration = end-start       
        #print "Detection Duration=" +str(duration)        
        return (ear_argmt)

##Fonctions Camera
def read_calib():
    cl = open(calib_local,'r')
    cd = open(calib_distant,'r')
    ls_calib = [cl,cd]
    for c in ls_calib:
        cam = c.readline()
        IP= c.readline()
        RP= c.readline()
        TP= c.readline()
        SP= c.readline()
        ##
        cam = cam.split('_') 
        IP= IP.split('_')   
        RP= RP.split('_') 
        TP= TP.split('_')   
        SP= SP.split('_')  
        ##
        cam = cam[1]
        IP1 =IP[1].split(',')  
        IP2 =IP[2].split(',')
        IP3 =IP[3].split(',') 

        RP1 =RP[1].split(',')  
       
        TP1 =TP[1].split(',')     
        
        SP1 = SP[1]
        ##
        if cam == "local":
            calib_param_local = [[IP1, IP2, IP3],RP1,TP1,SP1]
        elif cam == "distant":
            calib_param_distant = [[IP1, IP2, IP3],RP1,TP1,SP1]
    return (calib_param_local, calib_param_distant)
            
def take_photo_local(step, filepath, spectrum, exif):      
        if step == "detect":
                if spectrum == "visi":                        
                        cmd = "raspistill -n -q 40 -w 960 -h 1120 -rot 90 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t 1 -ss 5000 -br 54 -co 20 -o "+filepath
                if spectrum == "ir":
                        cmd = "raspistill -n -q 40 -w 48 -h 56 -rot 90 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t 1 -ss 12000 -br 50 -co 25 -o "+filepath
        if step == "capture":
                time_foc = 1
                cmdbase ="raspistill -n -q 100 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t " + str(time_foc) + " "                
                if spectrum == "visi":
                        cmdvisi = cmdbase + "-ss 4000 -br 54 -co 20 -o "  #"-ss 5000 -br 54 -co 20 -o "  #ss_old= 85000 4200
                        cmd = cmdvisi + filepath + exif
                if spectrum == "ir":
                        cmdir = cmdbase + "-ss 38000 -br 50 -co 30 -o "   #"-ss 40000 -br 50 -co 30 -o "  #ss_old= 115000 28000  25
                        cmd = cmdir + filepath + exif
        subprocess.call(cmd, shell=True)

def take_photo_distant(step, filepath, spectrum, exif):
        if step == "detect":
                if spectrum == "visi":
                        cmd = "raspistill -n -q 40 -w 960 -h 1120 -rot 90 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t 1 -ss 5000 -br 54 -co 20 -o "+filepath
                if spectrum == "ir":
                        cmd = "raspistill -n -q 40 -w 48 -h 56 -rot 90 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t 1 -ss 12000 -br 50 -co 25 -o "+filepath
        if step == "capture":
                time_foc = 1
                cmdbase ="raspistill -n -q 100 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t " + str(time_foc) + " " 
                if spectrum == "visi":
                        cmdvisi = cmdbase + "-ss 4000 -br 54 -co 20 -o "  #"-ss 5000 -br 54 -co 20 -o "  #5000
                        cmd = cmdvisi + filepath + exif
                if spectrum == "ir":
                        cmdir = cmdbase + "-ss 38000 -br 50 -co 30 -o " #"-ss 40000 -br 50 -co 30 -o "  
                        cmd = cmdir + filepath + exif 
        
        stdin,stout,stderr = client.exec_command(cmd)
        return stout

def write_exif(camera, session_name):
    # Maximum number of characters for camera parameters : 
    # 3*4 intrinsic + 1*3 radial + 1*2 tangent + 1*1 skew
    #Cam1 = distant
    if camera == "distant":
        '''
        IntrisicParameters_Cam =  [[349.3601, 0, 0], [111.1111, 349.7267, 0], [258.0883, 210.5905, 1 ]]                      
        RadialParameters_Cam =  [111.0504,-111.1651]
        TangentialParameters_Cam =  [111.1111,111.1111]
        SkewParameters_Cam =  111.1111
        '''
        IntrisicParameters_Cam =  calib_param_distant[0]                      
        RadialParameters_Cam =  calib_param_distant[1]  
        TangentialParameters_Cam =  calib_param_distant[2]  
        SkewParameters_Cam =  calib_param_distant[3]  
        NumeroDeCam = "1" 
    if camera == "local":
        IntrisicParameters_Cam =  calib_param_local[0]                      
        RadialParameters_Cam =  calib_param_local[1]  
        TangentialParameters_Cam =  calib_param_local[2]  
        SkewParameters_Cam =  calib_param_local[3]  
        NumeroDeCam = "2"
 
    # Compute String for camera : 
    IP0 = 'fx' + str(IntrisicParameters_Cam[0][0]) 
    IP1 = 's' + str(IntrisicParameters_Cam[1][0]) + 'fy' + str(IntrisicParameters_Cam[1][1])
    IP2 = 'cx' +  str(IntrisicParameters_Cam[2][0]) + 'cy' + str(IntrisicParameters_Cam[2][1])
    # RP : 
    RP = 'ra' + str(RadialParameters_Cam[0]) + 'rb' + str(RadialParameters_Cam[1])
    TP = 'ta' + str(TangentialParameters_Cam[0]) + 'tb' + str(TangentialParameters_Cam[1])
    SP = 'sp' + str(SkewParameters_Cam)
    # Num Cam : 
    NC = 'nc' + NumeroDeCam

    str_Imagedescription = IP0 + IP1 + IP2 + RP + TP + SP + NC #Exemple : fx349.3601s111.1111fy349.7267cx258.0883cy210.5905ra111.0504rb111.0504ta111.1111tb-111.1651sp111.1111nc1

    exif_str = " -x IFD1.ImageDescription=" + str_Imagedescription + " -x IFD1.Software=" + version_capture + " -x IFD1.Artist=" + session_name
    return exif_str

def take_photo_distant_detect(step, filepath, spectrum):
        if step == "detect":
                if spectrum == "visi":
                        cmd = "raspistill -n -q 40 -w 960 -h 1120 -rot 90 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t 1 -ss 7000 -br 54 -co 20 -o "+filepath
                if spectrum == "ir":
                        cmd = "raspistill -n -q 40 -w 48 -h 56 -rot 90 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t 1 -ss 12000 -br 50 -co 25 -o "+filepath
        if step == "capture":
                time_foc = 1
                cmdbase ="raspistill -n -q 100 -ex off -ISO 200 -awb incandescent -sh 0 -drc high -t " + str(time_foc) + " " 
                if spectrum == "visi":
                        cmdvisi = cmdbase + "-ss 5000 -br 54 -co 20 -o "  #5000
                        cmd = cmdvisi + filepath
                if spectrum == "ir":
                        cmdir = cmdbase + "-ss 40000 -br 50 -co 30 -o "  
                        cmd = cmdir + filepath  
        
        stdin,stout,stderr = client.exec_command(cmd)
        return stout

##

def text_draw(text, r,g,b, x, y,size, back, police):
        font = pygame.font.SysFont(police, size)
        text = font.render(text, 1, (r,g,b))
        textpos = text.get_rect()
        textpos.centerx = x
        textpos.centery = y
        back.blit(text, textpos)
		
def text_draw_ID(text, r,g,b, x, y,size, back, police):
        
		
        font = pygame.font.SysFont(police, size)
        texts = font.render(text, 1, (r,g,b))
        textpos = texts.get_rect()
        textwidth = textpos.width
        size_test = int(size*0.9)
        while textwidth >193 : #largeur max du texte dans la case "ID"
            font = pygame.font.SysFont(police, size_test)
            texts = font.render(text, 1, (r,g,b))
            textpos = texts.get_rect()
            textwidth = textpos.width
            size_test = int(size_test*0.9)
            
        textpos.centerx = x
        textpos.centery = y
        wb= 200
        xb = int(x-wb/2)
        back.blit(texts, textpos)

def text_draw_bold_italic(text, r,g,b, x, y,size, back, police):
        font = pygame.font.SysFont(police, size,True, True)
        text = font.render(text, 1, (r,g,b))
        textpos = text.get_rect()
        textpos.centerx = x
        textpos.centery = y
        back.blit(text, textpos)

def text_draw_left(text, r,g,b, x, y,size, back, police):
        font = pygame.font.SysFont(police, size)
        text = font.render(text, 1, (r,g,b))
        textpos = text.get_rect()
        textpos.x = x
        textpos.y = y
        back.blit(text, textpos)

def text_draw_left_bold(text, r,g,b, x, y,size, back, police):
        font = pygame.font.SysFont(police, size, True, False)
        text = font.render(text, 1, (r,g,b))
        textpos = text.get_rect()
        textpos.x = x
        textpos.y = y
        back.blit(text, textpos)

def text_draw_left_bold_italic(text, r,g,b, x, y,size, back, police):
        font = pygame.font.SysFont(police, size, True, True)
        text = font.render(text, 1, (r,g,b))
        textpos = text.get_rect()
        textpos.x = x
        textpos.y = y
        back.blit(text, textpos)

def text_draw_right(text, r,g,b, x, y,size, back, police):
        font = pygame.font.SysFont(police, size)
        text = font.render(text, 1, (r,g,b))
        textpos = text.get_rect()
        w= textpos[2]
        textpos.x = x-w
        textpos.y = y
        back.blit(text, textpos)

def init_ig(w_screen, h_screen):

        #Chargement et collage du fond
        bck = pygame.Surface(screen.get_size())
        bck = bck.convert()
        bck.fill((250,250,250))
        screen.blit(bck, (0,0))
        
        logo = pygame.image.load(UI_DIR + "/PNG/boot.png").convert_alpha()
        w_logo = logo.get_rect().size[0]
        h_logo = logo.get_rect().size[1]
        screen.blit(logo, ((w-w_logo)/2,(h-h_logo)/2))
 
        text_draw (version_capture + " _ PHYMEA SYSTEMS 2020",0,170,0,w/2,h*0.9,25, screen, 'Roboto Condensed')
        pygame.display.flip()

        ###Verifie et attend que Campi est démaré
        pygame.mixer.music.load(UI_DIR + "/Voices/boot.mp3")
        pygame.mixer.music.play()
        n_try=0
        while True:
            if n_try>7:# si au bout 7 tentatives de connexion le ssh nest pas initialisé alors le PI principale s'éteint
                cmd="sudo shutdown now"
                p = subprocess.call(cmd, stdout=subprocess.PIPE, shell=True)
                p.stdout.flush()
            col=[0,170,0]
            
            pygame.gfxdraw.filled_circle(screen, int(w*0.95) ,int(h*0.95), 15, [250,250,250]) #(surface, x, y, r, color)   
            pygame.gfxdraw.filled_circle(screen, int(w*0.95) ,int(h*0.95), 10, col) #(surface, x, y, r, color)
            pygame.display.flip()

            try: 
                client.connect(hostname='campi.local', username=DISTANT_USER, password=DISTANT_PWD,timeout=4)
                break
            except :               
                col=[250,250,250]
                pygame.gfxdraw.filled_circle(screen, int(w*0.95) ,int(h*0.95), 15, [250,250,250]) #(surface, x, y, r, color)   
                pygame.gfxdraw.filled_circle(screen, int(w*0.95) ,int(h*0.95), 10, col) #(surface, x, y, r, color)
                pygame.display.flip()
                time.sleep(1)
            n_try=n_try+1

        pygame.mixer.music.load(UI_DIR + "/Voices/init_done.mp3")
        pygame.mixer.music.play()
        n=1
        alpha =10
        while n<30:        
                time.sleep(0.05)
                bck.set_alpha(int(alpha))
                screen.blit(bck, (0,0))
                pygame.display.flip()
                n=n+1
                alpha = alpha*1.1 

def init_bck(w,h, ncode, check_para):
        c=[0,170,0]
        wear = (w/3)*2 #w/2
        winfo = w/3
        
        bck = pygame.Surface(screen.get_size())
        bck = bck.convert()
        bck.fill((250,250,250))
        bck.set_alpha(int(255))
        screen.blit(bck, (0,0))
        
        logo = pygame.image.load(UI_DIR + "/PNG/small_logo.png").convert_alpha()
        screen.blit(logo, (50,7))
        #rectangles pour afficher les IDs et les épis
        pygame.gfxdraw.rectangle(screen, (40,mar,wear-40,60),c)
        pygame.gfxdraw.rectangle(screen, (40,mar+70,wear-40,h-mar-100),c)
        #rectangle heure et NB capture
        pygame.gfxdraw.rectangle(screen, (wear+20,mar*0.1,(winfo-60)/2,mar*0.8),c) 
        pygame.gfxdraw.rectangle(screen, ((wear+20 + (winfo-60)/2)-1,mar*0.1,((winfo-60)/2)+2,mar*0.8),c) 
        #rectangle pour afficher la preview et les infos
        pygame.gfxdraw.rectangle(screen, (wear+20,mar,winfo-60,h-mar-30),c)
        pygame.gfxdraw.box(screen, (wear+20,mar+60,winfo-60,10),c)
        n=1
        near = 6#nombre d'épi et de case a representer
        while n <=near:
                if n < near:
                        pygame.gfxdraw.line(screen, (wear-40)/near*n+40,mar,(wear-40)/near*n+40,mar+59,c)
                        pygame.gfxdraw.line(screen, (wear-40)/near*n+40, mar+70, (wear-40)/near*n+40 ,h-31 ,c)
                        if n == 3 : 
                            pygame.gfxdraw.box(screen, ((wear-40)/near*n+40 -2 ,mar+70 ,4 , h-mar-100),c)#Ligne centrale épaisse
                text_draw (str(n),0,170,0,(wear-40)/near*n+40-((wear-40)/near)/2,mar+((h-mar)/2),45, screen, 'Roboto Condensed')
                n=n+1
        pygame.gfxdraw.box(screen, (40,mar+70,(wear-40),h*0.025),c)#boite camera 1 et camera 2
        text_draw ("Camera 1",250,250,250,40+(wear-40)/4,mar+70+13,35, screen, 'Roboto Condensed')
        text_draw ("Camera 2",250,250,250,40+3*(wear-40)/4,mar+70+13,35, screen, 'Roboto Condensed')
        #Rafraîchissement de l'écran
        pygame.display.flip()
        display_hd(w, h)
        display_time(w, h)
        display_session(w, h, session_name, ncode, check_para)
        
def display_detection(w, h, list_ID, list_ID_filter, ear_argmt, ncode, check_para):
        init_bck(w,h, ncode, check_para)
        near =  6# 3
        wear = int((w/3)*2)
        if ncode > 1:
                ls_pt = [] # list des épis potentiel [1,2,3]
                ls_prs = []#list des trous ex : [False, True, True]
                for x in range(1,near+1,1):
                        ls_pt.append(x)
                        ls_prs.append(x in ear_argmt)
                for e in ls_pt:
                        #Charge l'image de l'épi ou la fausse image
                        if ls_prs[e-1]== False:
                                coef_img = 0.6
                                filename = UI_DIR + "/PNG/ear_phymea.png"
                                img = pygame.image.load(filename).convert_alpha()
                                r,g,b = 250,0,0
                        if ls_prs[e-1]== True:
                                coef_img = 0.8
                                filename = DETECTION_DIR + "/ear" + str(int(e)) +".jpg"
                                img = pygame.image.load(filename).convert_alpha()
                        #récupère les codes
                        ear_id = str(list_ID[e-1])
                        if ear_id != "NO_DETECTION":
                                r,g,b= 0,170,0
                        if ear_id == "NO_DETECTION":
                                ear_id = "NO ID"
                                r,g,b = 250,0,0
                        wi, hi = img.get_rect().size           
                        h_rec = h-31 - mar*2  
                        ratio = float(h_rec)/hi
                        w_img = wi * float(ratio) *coef_img
                        h_img = hi * float(ratio) *coef_img
                        x = (wear-40)/near*(int(e)-1)+40 + ((wear-40)/near)/2 - w_img/2
                        y = mar+(h/2)-(h_img/2)#mar+200#130
                        img = pygame.transform.scale(img, (int(w_img), int(h_img)))
                        screen.blit(img, (x,y))
                        text_draw_ID (str(ear_id),r,g,b,(wear-40)/near*int(e)+40-((wear-40)/near)/2,mar+30,50, screen, 'Roboto Condensed')
                        if ls_prs[e-1]== False:
                                text_draw_ID ("NO EAR",255,255,255,(wear-40)/near*(int(e))+40-((wear-40)/near)/2,int(y+h_img/2),50, screen, 'Roboto Condensed')
                                text_draw_ID (str(e),255,255,255,(wear-40)/near*(int(e))+40-((wear-40)/near)/2,int(y+h_img/2)-50,50, screen, 'Roboto Condensed')
       
        if ncode ==1 :
                ls_pt = [] # list des épis potentiel [1,2,3]
                ls_prs = []#list des trous ex : [False, True, True]
                for x in range(1,near+1,1):
                        ls_pt.append(x)
                        ls_prs.append(x in ear_argmt)
                for e in ls_pt:
                        if ls_prs[e-1]== False:
                                ear_id = "NO EAR" 
                                coef_img = 0.6
                                filename = UI_DIR + "/PNG/ear_phymea.png"
                                img = pygame.image.load(filename).convert_alpha()
                                r,g,b = 250,0,0
                        if ls_prs[e-1]== True:
                                ear_id = str(list_ID_filter[0])
                                coef_img = 0.8
                                filename = DETECTION_DIR + "/ear" + str(int(e)) +".jpg"
                                img = pygame.image.load(filename).convert_alpha()
                                r,g,b= 0,170,0
                        wi, hi = img.get_rect().size
                        h_rec = h-31 - mar*2      
                        ratio = float(h_rec)/hi
                        w_img = wi * float(ratio) *coef_img
                        h_img = hi * float(ratio) *coef_img
                        x = (wear-40)/near*(int(e)-1)+40 + ((wear-40)/near)/2 - w_img/2
                        y = mar+(h/2)-(h_img/2)#130                        
                        img = pygame.transform.scale(img, (int(w_img), int(h_img)))
                        screen.blit(img, (x,y))
                        text_draw_ID (str(ear_id),r,g,b,(wear-40)/near*int(e)+40-((wear-40)/near)/2,mar+30,50, screen, 'Roboto Condensed')
                        if ear_id == "NO EAR":
                                #text_draw ("NO EAR",255,255,255,(wear-40)/near*(int(e))+40-((wear-40)/near)/2,int(y+h_img/2),24, screen, 'Roboto Condensed')
                                text_draw_ID (str(e),255,255,255,(wear-40)/near*(int(e))+40-((wear-40)/near)/2,int(y+h_img/2)-50,50, screen, 'Roboto Condensed')

        pygame.display.flip()
 
def scan_dir_capture():
	ls_capture_dir = os.listdir(capture_dir)
	#print ls_capture_dir
	
def display_dir(w, h, session_name):
        ls_dir = os.listdir(capture_dir)
        
        ls_session=[]
        xinfo = w*0.037
        n= h*0.2
        pygame.gfxdraw.box(screen, (xinfo,n+1,(w*0.41),h*0.73),[250,250,250])
        text_size =22     
        for i in ls_dir:
            if os.path.isdir(str(capture_dir)+str(i)):#affiche uniquement les "directories" et ignore les "fichiers"
                ls_session.append(str(i))#creer une liste qui ne cromprend que les directories = les sessions
                if i != session_name:
                    r,g,b = (50,50,50)
                if i == session_name:
                    r,g,b = (0,170,0)
                text_draw_left(i,r,g,b, xinfo ,n ,text_size, screen, 'Sans')        
                n += text_size+2
        pygame.display.flip()
        return (ls_session)
    
def new_capture(w,h):
        global buttonstate
        c=[0,200,0]
        pos_logo = (50,7)
        bck = pygame.Surface(screen.get_size())
        bck = bck.convert()
        bck.fill((250,250,250))
        mar = 60
        logo = pygame.image.load(UI_DIR + "/PNG/small_logo.png").convert_alpha()

        bck.set_alpha(int(60))
        screen.blit(bck, (0,0))
        bck.set_alpha(int(255))        
        screen.blit(bck, (0,0))
        
        im_session = pygame.image.load(UI_DIR + "/PNG/check_session.png").convert_alpha()
        im_session_continue = pygame.image.load(UI_DIR + "/PNG/check_session_continuer.png").convert_alpha()
        im_session_new = pygame.image.load(UI_DIR + "/PNG/check_session_new.png").convert_alpha()
        im_set =  pygame.image.load(UI_DIR + "/PNG/ID_setting.png").convert_alpha()
        im_set1 = pygame.image.load(UI_DIR + "/PNG/ID_setting1.png").convert_alpha()
        im_set2 = pygame.image.load(UI_DIR + "/PNG/ID_setting2.png").convert_alpha()
        im_set3 = pygame.image.load(UI_DIR + "/PNG/check_setting.png").convert_alpha()
        im_set4 = pygame.image.load(UI_DIR + "/PNG/check_setting1.png").convert_alpha()
        im_set5 = pygame.image.load(UI_DIR + "/PNG/check_setting2.png").convert_alpha()
        w_set = im_set.get_rect().size[0]
        h_set = im_set.get_rect().size[1]

##SESSION######################################################
        session_name = load_session()
        session_state = False
        pygame.mixer.music.load(UI_DIR + "/Voices/Def_session.mp3")
        pygame.mixer.music.play() 
        while session_state == False :
            ##Screen Continuer/Nouvelle
            screen.blit(im_session, ((w-w_set)/2,(h-h_set)/2))
            screen.blit(logo, pos_logo)
            ls_session = display_dir(w, h, "no session")    

            display_2_switch_session("", "")			
            pygame.display.flip()

            buttonstate = 0
            validation ()      
            ################
            
            if buttonstate=="GB":#Poursuivre une session
                    buttonstate=0  
                    pygame.mixer.music.load(UI_DIR + "/Voices/Select_session.mp3")
                    pygame.mixer.music.play()
                    screen.blit(im_session_continue, ((w-w_set)/2,(h-h_set)/2))
                    screen.blit(logo, pos_logo)
                    if len (ls_session) >0: #si il y a des sessions a poursuivre
                        if session_name != "NO_SESSION": #il y a une session en cours
                                #print "Session en cours: " +str(session_name)
                                ls_session = display_dir(w, h, session_name)  
                                session_temp=session_name #défini la session temporaire = dernière session en cours
                        if session_name == "NO_SESSION": #il n'y a pas de sessions en cours : premier démarrage ou disque dur vidé
                                #print "Pas de session en cours"
                                ls_session = display_dir(w, h, "No_Session")
                                session_temp=ls_session[0]# defini la session temporaire comme la première de la liste
                                pygame.display.flip()
                                time.sleep(2)                                                               
                                                            
                        while True:# Tant qu'une session n'est pas sélectionnée ou qu'une erreur n'est pas rencontré
                            ls_session = display_dir(w, h, session_temp)
                            display_2_switch_session("", "")
                            pygame.display.flip()
                            buttonstate = 0
                            validation ()
                            
                            if buttonstate=="GB":#selectionner
                                    session_name = session_temp
                                    save_session(session_name)# enregistre le nom de session pour que celui-ci soit accessible au prochain démarrage
                                    session_state = True
                                    break
                            if buttonstate=="RB":#session suivante
                                    if len(ls_session) != ls_session.index(session_temp)+1:
                                        session_temp = ls_session[ls_session.index(session_temp)+1]
                                    else :
                                        session_temp = ls_session[0]
                    else:
                        pygame.mixer.music.load(UI_DIR + "/Voices/no_session.mp3")
                        pygame.mixer.music.play()
                        time.sleep(3)
                    
            if buttonstate=="RB": #Nouvelle Sessions
                    buttonstate=0
                    pygame.mixer.music.load(UI_DIR + "/Voices/Saissir_session.mp3")
                    pygame.mixer.music.play()                    
                    screen.blit(im_session_new, ((w-w_set)/2,(h-h_set)/2))
                    screen.blit(logo, pos_logo) 
                    ls_session = display_dir(w, h, "no_session")   
                    #Parametre d'affichage de la boite de saisie
                    r,g,b= 250,250,250
                    c =[50,50,50]
                    x = int((w-w_set)/2 + w_set*0.53)
                    y = h_set*0.2
                    w_rec = int(w_set*0.35)
                    text_decal = 20
                    pygame.gfxdraw.box(screen, (x,y,w_rec,60),c)
                    text_draw_left_bold ("Saisir le nom de session",r,g,b,x+text_decal,y+text_decal,30, screen, 'Roboto Condensed')
                    pygame.display.flip()

                    current_string = []
                    str_temp =[]
                    while True:
                        try:   
                            inkey, uc = get_key()
                            character = uc.encode('utf8')
                        except :
                            print "PB Clavier"
                        
                        if inkey == K_BACKSPACE:
                            current_string = current_string[0:-1]
                        elif inkey == K_SPACE: 
                            current_string = current_string
                        elif inkey == K_RETURN or inkey == K_KP_ENTER:
                            #print "fin de saisi"
                            break 
                        elif str(character) in ls_uc:
                            keypress = str(character)
                            current_string.append(keypress)
        
                        str_temp = string.join(current_string,"")
                        pygame.gfxdraw.box(screen, (x,y,w_rec,45),c)
                        text_draw_left_bold (str(str_temp),r,g,b,x+text_decal,y+text_decal,24, screen, 'Roboto Condensed')
                        pygame.display.flip()  
                    
                    dir_name = str_temp
                    c =[ 0,170,0]
                    pygame.gfxdraw.box(screen, (x,y,w_rec,60),c)
                    text_draw_left_bold (str(dir_name),r,g,b,x+text_decal,y+text_decal,30, screen, 'Roboto Condensed')

                    if len(dir_name)>0 : #Si le nom de session est valide
                        Date =  time.strftime('%d-%m-%y', time.localtime())
                        path = str(capture_dir) + str(Date) + "_" + str(dir_name)
                        if not os.path.exists(path): #Si la session na pas déjà été crée                
                            mkdir_with_mode(path, 0777) 
                            #print "write path: "+str(path)
                            session_name = str(Date) + "_" + str(dir_name) # enregistre le nom de session pour que celui-ci soit accessible au reste du programme
                            save_session(session_name)# enregistre le nom de session pour que celui-ci soit accessible au prochain démarrage
                            #print "Session en cours: " +str(session_name)
                            session_state = True
                            ls_session = display_dir(w, h, session_name)  
                        else :
                            #print "Session already exists"
                            pygame.mixer.music.load(UI_DIR + "/Voices/session_exists.mp3")
                            pygame.mixer.music.play() 
                            time.sleep(4)
                    else :
                        #print "Auncun ID de session saisi"
                        pygame.mixer.music.load(UI_DIR + "/Voices/no_saisie.mp3")
                        pygame.mixer.music.play() 
                        time.sleep(4)
               

                    pygame.display.flip()

###UNICODE/MULTICODE 
        try :
            dir_session = str(capture_dir) + str(session_name)
            #print "TRY: Reading Session parameters> " + str (dir_session)
            ncode, check_para = load_para_session(dir_session)
            pygame.mixer.music.load(UI_DIR + "/Voices/Session_declare_long.mp3")
            pygame.mixer.music.play()	           
        except :
            #print "Session parameters File does not exist"
            pygame.mixer.music.load(UI_DIR + "/Voices/Session_declare_short.mp3")
            pygame.mixer.music.play()	
            time.sleep(3)	
            screen.blit(im_set, ((w-w_set)/2,(h-h_set)/2))
            screen.blit(logo, pos_logo)
            pygame.mixer.music.load(UI_DIR + "/Voices/id_param.mp3")
            pygame.mixer.music.play()
            ls_bt = ['g', 'r']
            for b in ls_bt :
                    if b == 'g' :
                            posx = int(((w)/2) - (w/2)*0.3)
                            col1 = [0,200,0]
                            col2 = [0,230,0]
                    if b == 'r' :
                            posx = int(((w)/2) + (w/2)*0.3)
                            col1 = [230,0,0]
                            col2 = [255,50,50]
                    y = int((h/5)*3.8)    
                    pygame.gfxdraw.filled_circle(screen, posx,y, 40, [200,200,200]) #(surface, x, y, r, color)
                    pygame.gfxdraw.aacircle(screen, posx,y, 40, [100,100,100]) #(surface, x, y, r, color)
                    pygame.gfxdraw.filled_circle(screen, posx,y, 28, col2) 
                    pygame.gfxdraw.aacircle(screen, posx,y, 28, col1)
                    pygame.gfxdraw.filled_circle(screen, posx,y, 22, [200,200,200]) #(surface, x, y, r, color)
                    pygame.gfxdraw.aacircle(screen, posx,y, 22, col1) #(surface, x, y, r, color)
         
            pygame.display.flip()
            buttonstate = 0
            validation ()
            pygame.mixer.music.load(UI_DIR + "/Voices/para_save.mp3")
            pygame.mixer.music.play()

            if buttonstate=="GB":
                    buttonstate=0  
                    screen.blit(im_set1, ((w-w_set)/2,(h-h_set)/2))
                    screen.blit(logo, (40,7))
                    ncode=1

            if buttonstate=="RB":
                    buttonstate=0
                    screen.blit(im_set2, ((w-w_set)/2,(h-h_set)/2))
                    screen.blit(logo, (40,7))
                    ncode=3

            pygame.display.flip()
            time.sleep(2)
            #Activation du check IDvsEar manuel
            pygame.mixer.music.load(UI_DIR + "/Voices/check_param.mp3")
            pygame.mixer.music.play()
            screen.blit(im_set3, ((w-w_set)/2,(h-h_set)/2))
            screen.blit(logo, (40,7))
            for b in ls_bt :
                    if b == 'g' :
                            posx = int(((w)/2) - (w/2)*0.3)
                            col1 = [0,200,0]
                            col2 = [0,230,0]
                    if b == 'r' :
                            posx = int(((w)/2) + (w/2)*0.3)
                            col1 = [230,0,0]
                            col2 = [255,50,50]
                    y = int((h/5)*3.8)       
                    pygame.gfxdraw.filled_circle(screen, posx,y, 40, [200,200,200]) #(surface, x, y, r, color)
                    pygame.gfxdraw.aacircle(screen, posx,y, 40, [100,100,100]) #(surface, x, y, r, color)
                    pygame.gfxdraw.filled_circle(screen, posx,y, 28, col2) 
                    pygame.gfxdraw.aacircle(screen, posx,y, 28, col1)
                    pygame.gfxdraw.filled_circle(screen, posx,y, 22, [200,200,200]) #(surface, x, y, r, color)
                    pygame.gfxdraw.aacircle(screen, posx,y, 22, col1) #(surface, x, y, r, color)
         
            pygame.display.flip()
            buttonstate = 0
            validation ()
            pygame.mixer.music.load(UI_DIR + "/Voices/thx_neutre.mp3")
            pygame.mixer.music.play()
            if buttonstate=="GB":
                    buttonstate=0  
                    screen.blit(im_set4, ((w-w_set)/2,(h-h_set)/2))
                    screen.blit(logo, (40,7))
                    check_para=True
            if buttonstate=="RB":
                    buttonstate=0
                    screen.blit(im_set5, ((w-w_set)/2,(h-h_set)/2))
                    screen.blit(logo, (40,7))
                    check_para=False
            pygame.display.flip()
            dir_session = str(capture_dir) + str(session_name)
            save_para_session(dir_session, ncode, check_para)# save les para de la session de la dossier de la session
            time.sleep(1)

        if ncode == "1" or ncode == 1:
            ncode=1
        else :
            ncode=3
        if check_para == "True" or check_para == True:
            check_para = True
        else : 
            check_para = False
        return (session_name, ncode, check_para)
	
def halt_pis():
                save_param(capture_amt)
                cmd="sudo shutdown now"
                stdin,stout,stderr = client.exec_command(cmd)
                client.close()
                time.sleep(2)
                pygame.mixer.music.load(UI_DIR + "/Voices/5sec.mp3")
                pygame.mixer.music.play()
                door_ctrl("close")
                time.sleep(2)# peut etre necessaire pour que la commande passe au premier coup
                p = subprocess.call(cmd, stdout=subprocess.PIPE, shell=True)
                p.stdout.flush()
               
def get_key():
  global buttonstate
  while 1:
    event = pygame.event.poll()
    if event.type == KEYDOWN:
        return event.key, event.unicode
    else:
      pass

def manual_entry(w,h):
        global buttonstate
        list_ID= []
        n_id=1
        near = 6 # 6E à changer
        wear = int((w/3)*2)
        im = pygame.image.load(UI_DIR + "/PNG/manual_entry.png").convert_alpha()
        w_set = im.get_rect().size[0]
        h_set = im.get_rect().size[1]     
        screen.blit(im, (w/2+((wear-w_set)/2)-10,mar + ((h-mar-h_set)/2)))
        
        while n_id <= near : # Tant que le nb d'ID est inf. au nb d'épis potentiel
                back_ear = False # Etat du retour en arrière
                r,g,b= 250,250,250
                c =[ 0,170,0]
                x = (wear-40)/near*int(n_id)+40-((wear-40)/near)+3
                y = mar+8
                w_rec = (wear-40)/near-5
                size = 50
                pygame.gfxdraw.box(screen, (x,y,w_rec,45),c)
                text_draw_ID ("Enter ID " + str(n_id),r,g,b,(wear-40)/near*int(n_id)+40-((wear-40)/near)/2,mar+30,size, screen, 'Roboto Condensed')
                pygame.display.flip()
                
                current_string = []
                while True:  #Saisie des ID 
                    inkey, uc = get_key()
                    
                    character = uc.encode('utf8')
                    if inkey == K_BACKSPACE: # Si retour arrière
                        current_string = current_string[0:-1] #Vire une lettre
                    elif inkey == K_RETURN or inkey == K_SPACE or inkey == K_DELETE or inkey == K_KP_ENTER : # SPACE ET DELETE NE SONT UTILE QUE POUR LA SAISIE "CLAVIER"
                        break  
                    elif str(character) in ls_uc:
                        keypress = str(character)
                        current_string.append(keypress)
                    str_temp = string.join(current_string,"")
                    r,g,b= 250,250,250
                    c =[ 0,170,0]
                    x = (wear-40)/near*int(n_id)+40-((wear-40)/near)+3
                    y = mar+8
                    w_rec = (wear-40)/near-5
                    pygame.gfxdraw.box(screen, (x,y,w_rec,45),c)
                    text_draw_ID(str(str_temp),r,g,b,(wear-40)/near*int(n_id)+40-((wear-40)/near)/2,mar+30,size, screen, 'Roboto Condensed')
                    pygame.display.flip()

                strg = string.join(current_string,"")
                if strg == "END_CODE" or strg == "NEXT_CODE" or strg == "DELETE_CODE":
                        if strg == "END_CODE":
                                list_ID.append("NO_DETECTION")
                                n_id = 6
                        if strg == "NEXT_CODE":
                                list_ID.append("NO_DETECTION")  
                        if strg == "DELETE_CODE":
                                back_ear = True
                                
                elif strg == "" :
                        if inkey == K_RETURN or inkey == K_KP_ENTER:
                                list_ID.append("NO_DETECTION")
                                n_id = 6
                        if inkey == K_SPACE:
                                list_ID.append("NO_DETECTION")   
                        if inkey == K_DELETE:
                            back_ear = True
                elif strg != "END_CODE" and strg != "NEXT_CODE" and strg != "" and strg != "DELETE_CODE":
                                list_ID.append(strg)
                
                ear_id = strg

                if ear_id != "END_CODE" and ear_id !="NEXT_CODE" and ear_id != "" and ear_id!= " " and ear_id != "DELETE_CODE":        
                        r,g,b= 0,0,0
                        c =[ 230,230,230]
                        x = (wear-40)/near*int(n_id)+40-((wear-40)/near)+3
                        y = mar+8
                        w_rec = (wear-40)/near-5
                        pygame.gfxdraw.box(screen, (x,y,w_rec,45),c)
                        text_draw_ID (str(ear_id),r,g,b,(wear-40)/near*int(n_id)+40-((wear-40)/near)/2,mar+30,size, screen, 'Roboto Condensed')
                        pygame.display.flip()
                if ear_id == "END_CODE" or ear_id == "NEXT_CODE" or ear_id == "" or ear_id == " " or ear_id == "DELETE_CODE":
                        ear_id = "NO ID"
                        r,g,b = 250,0,0
                        c =[ 230,230,230]
                        x = (wear-40)/near*int(n_id)+40-((wear-40)/near)+3
                        y = mar+8
                        w_rec = (wear-40)/near-5
                        pygame.gfxdraw.box(screen, (x,y,w_rec,45),c)
                        text_draw_ID (str(ear_id),r,g,b,(wear-40)/near*int(n_id)+40-((wear-40)/near)/2,mar+30,size, screen, 'Roboto Condensed')
                        pygame.display.flip()
                        
                if back_ear == False:
                    n_id +=1
                elif back_ear == True:
                    list_ID=list_ID[0:n_id-2]
                    if n_id >1:
                        n_id -=1
                    else :
                        n_id = 1
        lid = len(list_ID)
        while lid < near:
                
                list_ID.append("NO_DETECTION")
                c =[ 230,230,230]
                x = (wear-40)/near*int(lid)+40-((wear-40)/near)+3
                y = mar+8
                w_rec = (wear-40)/near-5
                pygame.gfxdraw.box(screen, (x,y,w_rec,45),c)
                r,g,b = 250,0,0
                text_draw_ID ("NO_ID",r,g,b,(wear-40)/near*int(lid)+40-((wear-40)/near)/2,mar+30,size, screen, 'Roboto Condensed')
                pygame.display.flip()
                lid += 1
                
        if check_para == True:
            display_cmd(w, h, "check_manu", list_ID_filter, 255)
            buttonstate = 0
            validation()
        if check_para == False:
            buttonstate="GB"
            
        if buttonstate == "GB":
                valid = True
                buttonstate = 0
                return list_ID, valid
        if buttonstate == "RB":
                list_ID=["NO_DETECTION","NO_DETECTION","NO_DETECTION","NO_DETECTION","NO_DETECTION","NO_DETECTION"]
                buttonstate = 0
                valid = False
                return list_ID, valid
                
def door_ctrl(action):
        if action =="open":
                #print"Open Door"
                if door_state() == 0: #si la porte est fermée
                        
                        GPIO.output(ARDUINO_CTRL_DOOR,1)
                        time.sleep(0.02) #passe les microsecondes en secondes car time.sleep demande des seconds
                        GPIO.output(ARDUINO_CTRL_DOOR,0)
                        while door_state() == 0: #tant que la porte est fermée
                                time.sleep(0.1)
                else :
                        print "Door Already Open!"
        if action =="close":
                #print "Close Door"
                if door_state() == 1: #si la porte est ouverte
                        GPIO.output(ARDUINO_CTRL_DOOR,1)
                        time.sleep(0.02) #passe les microsecondes en secondes car time.sleep demande des seconds
                        GPIO.output(ARDUINO_CTRL_DOOR,0)
                        while door_state() == 1: #tant que la porte est ouverte
                                time.sleep(0.1)
                else :
                        print "Door Already Close!"

def door_state():
        return GPIO.input(DOOR_STATE_PIN)

def led_ir_ctrl(puissance, action):
    if puissance == 0:
        GPIO.output(pinRes,1)
    if puissance == 1:
        GPIO.output(pinRes,0)
    time.sleep(0.2)
    if action == 0:
        GPIO.output(pinR2,1)
        GPIO.output(pinRes,1)
    if action == 1:
        GPIO.output(pinR2,0)


def led_visi_ctrl(puissance, action):
    if puissance == 0:
        GPIO.output(pinRes,1)
    if puissance == 1:
        GPIO.output(pinRes,0)
    time.sleep(0.2)
    if action == 0:
        GPIO.output(pinR1,1)
        GPIO.output(pinRes,1)
    if action == 1:
        GPIO.output(pinR1,0)
 
def check_freespace(disk_space_used):
        statvfs = os.statvfs(drive_dir)
        hd_size = statvfs.f_frsize * statvfs.f_blocks     # Size of filesystem in bytes
        free_size = statvfs.f_frsize * statvfs.f_bfree      # Actual number of free bytes
        pct_used = (float(hd_size- free_size) / int(hd_size))* 100
        if pct_used >=disk_space_used:
                save_param(capture_amt)
                cmd="sudo shutdown now"
                stdin,stout,stderr = client.exec_command(cmd)
                client.close()
                time.sleep(2)
                pygame.mixer.music.load(UI_DIR + "/Voices/espace_disque.mp3")
                pygame.mixer.music.play()
                door_ctrl("close")
                time.sleep(13)# peut etre necessaire pour que la commande passe au premier coup
                p = subprocess.call(cmd, stdout=subprocess.PIPE, shell=True)
                p.stdout.flush()

def checkDriveAndGetMountPath(usb_slots, phymea_directory):
        usb_slot_full_path = "/dev/disk/by-path/"+ usb_slots # full path of the disk on usb slot   
        if isDiskPluggedOnUSBSlotAndHasPartition(usb_slot_full_path):
                partitions = getMountedPartitionListOnUSBSlot(usb_slot_full_path)
                if len(partitions) == 0:
                        path_to_partition = mountPartitionManually(usb_slot_full_path)
                elif len(partitions) == 1:
                        path_to_partition = partitions[0][5]
                elif len(partitions) > 1:
                        for partition in partitions :
                                if isPhymeaDirectoryOnPartition(partition, phymea_directory):
                                        path_to_partition = partition[5]
                        if path_to_partition is None:
                                path_to_partition = getLargestAvailablePartition(partitions)
                return (True, path_to_partition)
        return (False, None)

def isDiskPluggedOnUSBSlotAndHasPartition(usb_slot):
        cmd = 'ls -1 ' + usb_slot + '*part*'
        plugged_usb_disk_partitions = sendShellCommandAndGetOutputAsPythonList(cmd)
        if plugged_usb_disk_partitions:
                return True
        return False

def getMountedPartitionListOnUSBSlot(usb_slot):
        cmd = 'for f in ' + usb_slot + '*part*; do result=$(df "$f" 2>/dev/null | tail -n +2 | grep /dev/sd); if [ -n "$result" ]; then echo $result; fi ; done'
        partitions = sendShellCommandAndGetOutputAsPythonList(cmd)
        return partitions

def mountPartitionManually(usb_slot):
       manual_mount_point = os.environ["MANUAL_MOUNT"]
       cmd = 'sudo mkdir -p ' + manual_mount_point + '; sudo chmod 755 -R ' + manual_mount_point + '; sudo mount ' + usb_slot + '-part1 ' + manual_mount_point
       _ = sendShellCommandAndGetOutputAsPythonList(cmd)
       return manual_mount_point

def searchPhymeaDirectoryOnPartitions(partition, phymea_directory):
        return os.path.isdir(os.path.join(partition[5],phymea_directory))

def sendShellCommandAndGetOutputAsPythonList(command):
        process = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True) #send command to buffer
        stdout = process.communicate()[0].splitlines()
        output = [] # list to hold partitions found
        for line in stdout:
                output.append((line.split()))
        return output

def check_files_after_sequence(capture_dir, session_name, ear_argmt_C1, output1, ear_argmt_C2, output2):
    '''
        Check if the sequence was correctly ran
        Returns True only if all expected files are present and of a decent size (pictures are big)
    '''
    _filelist=[]

    if len(ear_argmt_C1) != 0:  # Camera 1
        _filelist = _filelist + [os.path.join(capture_dir, session_name, t + str(x) + output1) for t in ("V","I") for x in range(1,7)]
    if len(ear_argmt_C2) != 0:  # Camera 2
        _filelist = _filelist + [os.path.join(capture_dir, session_name, t + str(x) + output2) for t in ("V","I") for x in range(1,7)]
    for f in _filelist:
        if not os.path.isfile(f):  # No file, no picture :/
            return False
        elif not (os.path.getsize(f) >= 500000):  # File too small to be a correct picture
            return False
    return True  # All expected files are here !

if __name__ == "__main__":

    GPIO.add_event_detect(40, GPIO.FALLING, callback=REDbutton, bouncetime=500)#dectecte si le bouton RED est pressé
    GPIO.add_event_detect(32, GPIO.FALLING, callback=GREENbutton, bouncetime=500)#dectecte si le bouton de GREEN est pressé
    GPIO.add_event_detect(37, GPIO.FALLING, callback=BLUEbutton, bouncetime=500)#dectecte si le bouton de BLUE est pressé

    USB_SLOT_ADRESS_0 = os.environ["USB_SLOT_ADRESS_0"]
    USB_SLOT_ADRESS_1 = os.environ["USB_SLOT_ADRESS_1"]
    phymea_directory = "EarBox_drive/Session/"

    w = 1920
    h = 1080
    ### Nécessaire pour que Pygame démarre en mode console
    try:
        signal.signal(signal.SIGHUP, handler)
    except AttributeError:
        pass
    ###Pygame initialisation
    pygame.init()
    pygame.mouse.set_visible(False)

    ####Check si disque dur branché
    status, drive_dir = checkDriveAndGetMountPath(USB_SLOT_ADRESS_0, phymea_directory)
    if not status:
            status, drive_dir = checkDriveAndGetMountPath(USB_SLOT_ADRESS_1, phymea_directory)
            if not status:
                    buttonstate = 0
                    pygame.mixer.music.load(UI_DIR + "/Voices/no_hdd.mp3")
                    pygame.mixer.music.play()
                    ###Verifie et attend que Campi est démaré
                    while True:
                        try: 
                            client.connect(hostname='campi.local', username=DISTANT_USER, password=DISTANT_PWD,timeout=4)
                            break
                        except :
                            time.sleep(0.25)
                    validation()
                    if buttonstate == "RB" or buttonstate == "GB":
                        buttonstate = 0
                        cmd="sudo shutdown now"
                        stdin,stout,stderr = client.exec_command(cmd)
                        client.close()
                        time.sleep(2)
                        pygame.mixer.music.load(UI_DIR + "/Voices/5sec.mp3")
                        pygame.mixer.music.play()
                        door_ctrl("close")
                        time.sleep(4)# peut etre necessaire pour que la commande passe au premier coup
                        p = subprocess.call(cmd, stdout=subprocess.PIPE, shell=True)
                        p.stdout.flush()
                    if buttonstate == "BB":
                        buttonstate = 0
                        raise IOError("No disk found on USB")

    capture_dir = os.path.join(drive_dir, phymea_directory)

    ##Ouverture de la fenêtre Pygame
    screen = pygame.display.set_mode((w, h))
    init_ig(w, h)

    ##vérifie l'existance des directories
    create_directories()
    ##charge les parametres de calibration des cameras
    calib_param_local, calib_param_distant = read_calib()
    ##charge les parametres sauvegardés
    capture_amt = load_param()
    time_manual_def(w,h, "start")
        


    ####Déclaration de la session initiale
    session_name, ncode, check_para = new_capture(w,h)
    init_bck(w,h, ncode, check_para)

    ##Paramètres d'ergonomie au setup
    door_ctrl("open")
    led_visi_ctrl(0,1)

    ###############!!!!!!!!!Ligne nécessaire pour retourner à l'ancien algo de white_balance pour obtenir des photo IR noir et blanc (et non violette ou sur saturées)!!!!!!!!
    cmd = "sudo vcdbg set awb_mode 0"
    stdin,stout,stderr = client.exec_command(cmd)#Pi distant
    subprocess.call(cmd, shell=True)#Pi Local
    ###############Set time on distant Pi##################################################################
    local_time = datetime.datetime.now()
    cmd = 'sudo date +%Y%m%d -s "' + str(local_time.year) + str(local_time.month) + str(local_time.day) + '"'
    stdin,stout,stderr = client.exec_command(cmd)#Pi distant
    cmd = 'sudo date +%T -s "' + str(local_time.hour) + ":" + str(local_time.minute) + ":" + str(local_time.second) + '"'
    stdin,stout,stderr = client.exec_command(cmd)#Pi distant
    #########################################################################################################
    print "EARBOX User_Interface start"
    while True:
        try :   

            display_cmd(w, h, "capture", list_ID_filter, 180)
            display_time(w, h)
            display_c_amnt(w, h, capture_amt)
            buttonstate = 0
            check_freespace(95) #proportion du disque utilisé normalement 95 pour 95%
            ear_capt_button(5)#fonction admin pour reprendre la main sous pygame qui allume/éteint les boutons en plus, pour que ce soit transparent pour l'utilisateur
            if os.path.exists(os.environ["MANUAL_MOUNT"]+"1"):        
                pygame.mixer.music.load(UI_DIR + "/Voices/no_hdd.mp3")
                pygame.mixer.music.play()
                time.sleep(8)
                halt_pis()        
            #####
            if buttonstate == "BB":
                    buttonstate = 0
                    display_cmd(w, h, "halt", list_ID_filter, 255)
                    validation_all()
                    if buttonstate == "GB":
                            buttonstate = 0
                            state_set = 0                        
                            while state_set == 0:
                                display_cmd(w, h, "settings", list_ID_filter, 255)
                                validation_all()
                                if buttonstate == "BB":
                                    buttonstate = 0
                                    state_set = 2
                                if buttonstate == "RB":
                                    buttonstate = 0
                                    time_manual_def(w,h, "")
                                    
                                if buttonstate == "GB":
                                    state_set = 1
                                    display_cmd(w, h, "volume_set", list_ID_filter, 255)
                                    volume = pygame.mixer.music.get_volume()
                                    display_volume(w, h, volume)
                                    while state_set == 1:
                                            validation_all()
                                            if buttonstate == "BB":
                                                    buttonstate = 0
                                                    state_set = 0
                                            if buttonstate == "GB":
                                                    buttonstate = 0
                                                    if volume < 1:
                                                            volume += 0.1
                                                            display_volume(w, h, volume)
                                                            pygame.mixer.music.set_volume(volume)
                                                            pygame.mixer.music.load(UI_DIR + "/Voices/Open_tech.mp3")
                                                            pygame.mixer.music.play()
                                            if buttonstate == "RB":
                                                    buttonstate = 0
                                                    if volume >0:
                                                            volume -= 0.1
                                                            display_volume(w, h, volume)
                                                            pygame.mixer.music.set_volume(volume)
                                                            pygame.mixer.music.load(UI_DIR + "/Voices/Open_tech.mp3")
                                                            pygame.mixer.music.play()
                                init_bck(w,h, ncode, check_para)

                                            
                    if buttonstate == "RB":
                            buttonstate = 0
                            pygame.mixer.music.load(UI_DIR + "/Voices/extinction.mp3")
                            pygame.mixer.music.play()
                            halt_pis()
                    if buttonstate == "BB":
                            buttonstate = 0
                            init_bck(w,h, ncode, check_para)
            
            if buttonstate == "GB":
                    buttonstate = 0
                    session_name, ncode, check_para = new_capture(w,h)
                    init_bck(w,h, ncode,check_para)

            if buttonstate == "RB":
                    buttonstate = 0
                    #Entrée des IDs
                    init_bck(w,h, ncode,check_para) 
                    led_visi_ctrl(0, 0)
                    door_ctrl("close") 
                    ###############################################################################################
                    #détections des épis
                    ear_argmt = ear_detection()                
                    ear_argmt_C1 = []
                    ear_argmt_C2 = []
                    for e in ear_argmt: #Distribue les épis détecté en fonction des cameras
                        if int(e) <=3:
                            ear_argmt_C1.append(e)
                        if int(e) >3 and int(e) <7:
                            ear_argmt_C2.append(e)
                        elif int(e) >=7:
                            print "ear_detection() ERROR > ear_argmt contient un nb d'épi >6 par exemple"
                    display_progress(w, h,'code', 3)   
                    display_detection(w, h, ["","","","","",""], ["","","","","",""], ear_argmt, ncode, check_para)
                    ################################################################################################
                    list_ID, valid = manual_entry(w,h)
                    list_ID = np.array(list_ID)
                    list_ID_filter = list_ID[list_ID!="NO_DETECTION"] 
                    list_ID_C1 = list_ID [:3] #recup les 3 premiers élements de la liste
                    list_ID_C2 = list_ID [-3:] #recup les 3 derniers élements de la liste               
                    list_ID_filter_C1 = list_ID_C1[list_ID_C1!="NO_DETECTION"]
                    list_ID_filter_C2 = list_ID_C2[list_ID_C2!="NO_DETECTION"]
                    
                    #######################################
                    if valid == False:
                            display_info(w, h, "Manual entry: capture aborted by user" , 'red')
                    if valid == True : 
                    #Validation barcode et correspondance avec épis
                            n_ID = len(list_ID_filter)# verifier comment ca ca tourne lorsque list_ID_filter ne contient rien
                            n_ear = len(ear_argmt)
                            ls_id = [] # list id
                            ls_ear = []#list épi
                            if ncode >1 :
                                    #check la correspondance
                                    near_pot = 6
                                    for x in range(1,near_pot+1,1):
                                            ls_ear.append(x in ear_argmt)
                                            if list_ID[x-1] == 'NO_DETECTION':
                                                    ls_id.append(False)
                                            if list_ID[x-1] != 'NO_DETECTION':
                                                    ls_id.append(True)
                                    if ls_id != ls_ear:
                                            correspond = False
                                    if ls_id == ls_ear:
                                            correspond =True
                                    #alertes        
                                    if n_ID != n_ear and n_ear>0 and n_ID>0: #Si les Nb ID != Nb d'épis alors qu'ils existent (>0)
                                            display_detection(w, h, list_ID, list_ID_filter, ear_argmt, ncode, check_para)
                                            #print "Nb barcodes et épis différents"
                                            pygame.mixer.music.load(UI_DIR + "/Voices/codevsear.mp3")
                                            pygame.mixer.music.play()
                                            if n_ID < n_ear :
                                                    display_cmd(w, h, "wrg_nb_multicode", list_ID_filter,255)
                                            if n_ID > n_ear :
                                                    display_cmd(w, h, "wrg_nb_multicode_ear", list_ID_filter,255)

                                            display_info(w, h, "Lack of ear or ID: capture aborted" , 'red')
                                            
                                    if n_ID==0: #Si aucun ID n'est saisi
                                            #print "No code"
                                            pygame.mixer.music.load(UI_DIR + "/Voices/nocode.mp3")
                                            pygame.mixer.music.play()
                                            display_cmd(w, h, "wrg_nb_multicode", list_ID_filter,255)
                                            display_info(w, h, "Lack of ear or ID: capture aborted" , 'red')
                                                    
                                    if n_ear == 0: #Si aucun épi n'est détecté
                                            display_detection(w, h, list_ID, list_ID_filter, ear_argmt, ncode, check_para)
                                            #print "No ear"
                                            pygame.mixer.music.load(UI_DIR + "/Voices/noear.mp3")
                                            pygame.mixer.music.play()
                                            display_cmd(w, h, "no_ear", list_ID_filter,255)
                                            display_info(w, h, "No ear detected: capture aborted" , 'red')
                                            
                                    if correspond == False and n_ID == n_ear: #Si la correspondance n'est pas respectée
                                            display_detection(w, h, list_ID, list_ID_filter, ear_argmt, ncode, check_para)
                                            #print "Mauvaise correspondance épi-code"
                                            pygame.mixer.music.load(UI_DIR + "/Voices/wrong_corres.mp3")
                                            pygame.mixer.music.play()
                                            display_cmd(w, h, "wrong_corres", list_ID_filter,255)
                                            display_info(w, h, "Codes and ears position do not match : capture aborted" , 'red')
                                            
                                    len_ls_uni= len(set(list_ID_filter))# retire les doublons (set)
                                    len_ls_ID = len(list_ID_filter)        
                                    if len_ls_uni != len_ls_ID : # CHECK si les ID sont unique = si la liste des ID unique est différent de la list des ID c'est qui il y a des doublons
                                            correspond = False
                                            pygame.mixer.music.load(UI_DIR + "/Voices/multi_code_non_unik.mp3")
                                            pygame.mixer.music.play()
                                            display_cmd(w, h, "wrg_nb_multicode", list_ID_filter,255)
                                            display_info(w, h, "IDs are not unique: capture aborted" , 'red')
                                    #capture
                                    if n_ID == n_ear and n_ear >0 and correspond == True:
                                            display_detection(w, h, list_ID, list_ID_filter, ear_argmt, ncode, check_para)
                                            capture_amt = ear_capture(list_ID_filter, list_ID_filter_C1,list_ID_filter_C2,ear_argmt_C1,ear_argmt_C2, capture_amt, ncode)
                            if ncode ==1 :
                                    #alertes
                                    if n_ID > 1:
                                            display_detection(w, h, list_ID, list_ID_filter, ear_argmt, ncode, check_para)
                                            #print "Barcodes trop nombreux"
                                            pygame.mixer.music.load(UI_DIR + "/Voices/morecode.mp3")
                                            pygame.mixer.music.play()
                                            display_cmd(w, h, "wrg_nb_unicode", list_ID_filter,255)
                                            display_info(w, h, "BarCode is not unique: capture aborted" , 'red')
                                    if n_ID == 0:
                                            #print "Barcode absent"
                                            pygame.mixer.music.load(UI_DIR + "/Voices/nocode.mp3")
                                            pygame.mixer.music.play()
                                            display_cmd(w, h, "wrg_nb_unicode", list_ID_filter,255)
                                            display_info(w, h, "BarCode is not unique: capture aborted" , 'red')
                                    if n_ear == 0:
                                            display_detection(w, h, list_ID, list_ID_filter, ear_argmt, ncode, check_para)
                                            #print "Barcode absent ou trop nombreux"
                                            pygame.mixer.music.load(UI_DIR + "/Voices/noear.mp3")
                                            pygame.mixer.music.play()
                                            display_cmd(w, h, "no_ear", list_ID_filter,255)
                                            display_info(w, h, "No ear detected: capture aborted" , 'red')
                                    #capture
                                    if n_ID == 1 and n_ear != 0 :
                                            display_detection(w, h, list_ID, list_ID_filter, ear_argmt, ncode, check_para)
                                            capture_amt = ear_capture(list_ID_filter, list_ID_filter_C1,list_ID_filter_C2, ear_argmt_C1,ear_argmt_C2, capture_amt, ncode)
                    client.close()
                    door_ctrl("open")
                    led_visi_ctrl(0,1)
                    client.connect(hostname='campi.local', username=DISTANT_USER, password=DISTANT_PWD,timeout=4)
        except EnvironmentError as e: # utile dans le cas ou le disque dur est démonté pendant le fonctionnement 
            halt_pis()
            print 'EnvironmentError: ' , e  
    #################################END######################################################
