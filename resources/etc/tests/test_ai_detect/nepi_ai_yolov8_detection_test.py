#!/usr/bin/env python
#
# Copyright (c) 2024 Numurus <https://www.numurus.com>.
#
# This file is part of nepi applications (nepi_apps) repo
# (see https://https://github.com/nepi-engine/nepi_apps)
#
# License: nepi applications are licensed under the "Numurus Software License", 
# which can be found at: <https://numurus.com/wp-content/uploads/Numurus-Software-License-Terms.pdf>
#
# Redistributions in source code must retain this top-level comment block.
# Plagiarizing this software to sidestep the license obligations is illegal.
#
# Contact Information:
# ====================
# - mailto:nepi@numurus.com
#

print('')
print("RUNNING YoloV8 AI DETECTION TEST")
print('-------------------------')

print('')
print("Importing packages")

import os
import time
import copy
import sys
import torch
import cv2
import random
from pathlib import Path

from ultralytics import YOLO



# Get the path of the current script file
script_dir = os.path.dirname(__file__)



NUM_TESTS=100
IMAGES_DIR=os.path.join(script_dir, 'images')
WEIGHT_FILE="common_objects_yolov8_640_tiny.pt"
THRESHOLD=0.3


IMAGE_FILE_TYPES = ['jpg','JPG','jpeg','png','PNG']
 
   ######################################          




def get_files(folder_path):
    img_files = []
    xml_files = []
    txt_files = []
    if os.path.exists(folder_path) == False:
        print('Folder not found: ' + folder_path)
    else:
        path, dirs, files = next(os.walk(folder_path))
        for file in files:
            f_ext = os.path.splitext(file)[1]
            f_ext = f_ext.replace(".","")
            if f_ext in IMAGE_FILE_TYPES:
                img_files.append(file)
    return img_files


def is_gray(cv2_img):
    cv_shape = cv2_img.shape
    if len(cv_shape) == 2:
      return True
    elif len(cv_shape) == 3 and cv_shape[2] == 1:
      return True
    else:
      return False



######################################
if __name__ == '__main__':
    print('')
    print("Getting test images from: " + str(IMAGES_DIR))

    image_files = get_files(IMAGES_DIR)
    num_files=len(image_files)

    if num_files == 0:
        print("No images found at: " + str(IMAGES_DIR))
    else:
        print("Found " + str(num_files) + " images")
        ######################################
        # Load Model
        model_path=os.path.join(script_dir, WEIGHT_FILE)
        weight_file_path=model_path
        print('')
        print("Loading model: " + str(weight_file_path))

        device = 'cpu'
        has_cuda = torch.cuda.is_available()
        print("CUDA available: " + str(has_cuda))
        if has_cuda == True:
            cuda_count = torch.cuda.device_count()
            print("CUDA GPU Count: " + str(cuda_count))
            if cuda_count > 0:
                device = 'cuda'

        print("Loading model: " + str(weight_file_path))
        ai_model = YOLO(weight_file_path)
        ai_model.conf = THRESHOLD  # Confidence threshold (0-1)


        ###########################
        # Run Tests
        random_int = random.randint(1, num_files)-1
        image_file=os.path.join(IMAGES_DIR, image_files[random_int])
        cv2_img = cv2.imread(image_file)
        if cv2_img is None:
            print("Failed to import img file " + str(image_file))
        else:
            if is_gray(cv2_img):
                cv2_img = cv2.cvtColor(cv2_img, cv2.COLOR_GRAY2BGR)
            else:
                cv2_img = cv2.cvtColor(cv2_img, cv2.COLOR_BGR2RGB)

            ###########################
            print('')
            print("Priming the Model")
            try:
                results = ai_model(cv2_img, conf=THRESHOLD, verbose=False, device=device)            
            except Exception as e:
                print("Failed to process detection with exception: " + str(e))


            ###########################
            # Run Tests
            print('')
            print("Running Detection Speed Test with" + str(NUM_TESTS) + " Images")
            elapsed_time=0
            for i in range(1, NUM_TESTS):

                random_int = random.randint(1, num_files)-1
                image_file=os.path.join(IMAGES_DIR, image_files[random_int])
                cv2_img = cv2.imread(image_file)
                if cv2_img is None:
                    print("Failed to import img file " + str(image_file))
                else:
                    if is_gray(cv2_img):
                        cv2_img = cv2.cvtColor(cv2_img, cv2.COLOR_GRAY2BGR)
                    else:
                        cv2_img = cv2.cvtColor(cv2_img, cv2.COLOR_BGR2RGB)
                    
                    start_time = time.time()
                    try:
                        # Inference
                        results = ai_model(cv2_img, conf=THRESHOLD, verbose=False, device=device)
                    except Exception as e:
                        print("Failed to process detection with exception: " + str(e))
                    end_time = time.time()


                    detect_time = end_time - start_time
                    elapsed_time = elapsed_time + detect_time


            ######################
            # Print Results
            rescale_ratio = 1

            cv2_img_shape = cv2_img.shape
            cv2_img_width = cv2_img_shape[1]
            cv2_img_height = cv2_img_shape[0]
            cv2_img_area = cv2_img_shape[0] * cv2_img_shape[1]
            #print("image size: " + str(cv2_img.shape))


            detect_dict_list = []
            for i, idf in enumerate(ids):
                id = int(idf)
                det_name = id #classes[id]
                det_id = id
                det_prob = confs[i]
                det_box = boxes[i]
                det_area = (det_box[2] - det_box[0]) * (det_box[3] - det_box[1])
                detect_dict = {
                    'name': det_name, # Class String Name
                    'id': det_id, # Class Index from Classes List
                    'uid': '', # Reserved for unique tracking by downstream applications
                    'prob': det_prob, # Probability of detection
                    'xmin': int(det_box[0] ),
                    'ymin': int(det_box[1] ) ,
                    'xmax': int(det_box[2] ),
                    'ymax': int(det_box[3]),
                    'area_pixels': int(det_area),
                    'area_ratio': det_area / cv2_img_area
                }

                # Rescale to orig image size
                
                detect_dict['xmin'] = int(detect_dict['xmin'] * rescale_ratio)
                detect_dict['ymin'] = int(detect_dict['ymin'] * rescale_ratio)
                detect_dict['xmax'] = int(detect_dict['xmax'] * rescale_ratio)
                detect_dict['ymax'] = int(detect_dict['ymax'] * rescale_ratio)
                detect_dict_list.append(detect_dict)

            print("Got detect dict list: " + str(detect_dict_list))
            
            drate=float(1.0)/elapsed_time * NUM_TESTS
            print("")
            print("")
            print(f"Ran 100 detections in: {elapsed_time:.6f} seconds")
            print(f"Average detection rate: {drate:.2f} hz")

