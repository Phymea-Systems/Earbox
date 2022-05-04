classdef EarClass < handle
    
    properties (Constant)
        PX2CM = 0.0108;
    end
    
    properties
        dirpath;
        code;
        faces;
        facesIdx;
    end
    
    properties (Transient)
        length;
        width;
        rank_count_base;
        rank_count_apex;
        rank_count_median;
        isFacesSet;
    end
    
    methods
        function obj = EarClass(workdir,code)
            obj.dirpath = fullfile(workdir,code);
            obj.code = code;
            obj.isFacesSet = false;
            obj.faces;
        end
        
        function outstruct = get.faces(obj)
            if ~obj.isFacesSet
                faceList = ls(obj.dirpath);
                faceList = strsplit(faceList,{'\n',' ','\t'},'CollapseDelimiters',true);
                faceList(end) = [];
                obj.facesIdx = str2num(cell2mat(faceList)')';
                for face = obj.facesIdx
                    obj.faces{face} = obj.getFaceByIdx(face);
                end
                obj.isFacesSet = true;            
            end
            outstruct = obj.faces;
        end
        
        function FaceEarObject = getFaceByIdx(obj,idx)
            FaceEarObject = FaceEarClass(obj.dirpath,obj.code,idx);
        end
        
        function outstruct = getFacesTraitByMethod(obj,method)
            faceTraits = struct;
            for face = obj.facesIdx
                faceTraits.(['f' num2str(face)]) = obj.faces{face}.(method);
            end
            outstruct = faceTraits;
        end
        
        function vect = traitStructToVect(obj,instruct)
            n=1;
            vect = nan(numel(obj.facesIdx),1);
            for face = obj.facesIdx
                vect(n) = instruct.(['f' num2str(face)]);
                n=n+1;
            end
        end
        
        function val = get.length(obj)
            vect = obj.traitStructToVect(obj.getFacesTraitByMethod('horzAxisLength'));
            val = obj.px2cm(max(vect));
        end
        
        function val = get.width(obj)
            vect = obj.traitStructToVect(obj.getFacesTraitByMethod('earMaxDiameter'));
            val = obj.px2cm(max(vect));
        end
        
        function val = allRankCount(obj)
            toto = obj.getFacesTraitByMethod('ringCount');
            val = 1;
        end
        
        function val = get.rank_count_base(obj)
            obj.allRankCount
            vect = obj.traitStructToVect(obj.getFacesTraitByMethod('ringCount.ringCountAvgBot'));
            val = obj.px2cm(max(vect));
        end
        
        function val = get.rank_count_apex(obj)
            vect = obj.traitStructToVect(obj.getFacesTraitByMethod('ringCount.ringCountAvgTop'));
            val = obj.px2cm(max(vect));
        end
        
        function val = get.rank_count_median(obj)
            vect = obj.traitStructToVect(obj.getFacesTraitByMethod('ringCount.ringCountAvgMid'));
            val = obj.px2cm(max(vect));
        end
        
        
        
    end
    
    methods (Access = private)
        function cm_val = px2cm(obj,px_val)
            cm_val = px_val * obj.PX2CM;
        end
    end
        
end