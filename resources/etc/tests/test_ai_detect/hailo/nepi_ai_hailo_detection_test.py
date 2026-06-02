#!/usr/bin/env python
#
# Copyright (c) 2024 Numurus <https://www.numurus.com>.
#
# This file is part of nepi applications (nepi_ai_frameworks) repo
# (see https://https://github.com/nepi-engine/nepi_ai_frameworks)
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
print("RUNNING Hailo AI DETECTION TEST")
print('-------------------------')

print('')
print("Importing packages")

import os
import time
import sys
import yaml
import cv2
import numpy as np
import random
from typing import List, Tuple, Optional, Dict
from PIL import Image




try:
    from hailo_platform import (HEF, Device, VDevice, HailoStreamInterface, InferVStreams, ConfigureParams,
    InputVStreamParams, OutputVStreamParams, InputVStreams, OutputVStreams, FormatType)
    #from hailo_platform import *
    HAILO_AVAILABLE = True
    HAILO_IMPORT_ERROR = None
except ImportError as e:
    HAILO_AVAILABLE = False
    HAILO_IMPORT_ERROR = str(e)

print("HAILO_AVAILABLE " + str(HAILO_AVAILABLE))
print("HAILO_IMPORT_ERROR " + str(HAILO_AVAILABLE))


# Get the path of the current script file
script_dir = os.path.dirname(__file__)


NUM_TESTS = 100
IMAGES_DIR = os.path.join(script_dir, '..', 'images')
#MODEL DOWNLOAD LINKS
#'https://github.com/hailo-ai/hailo_model_zoo/blob/master/docs/public_models/HAILO8L/HAILO8L_object_detection.rst'
#'https://hailo-model-zoo.s3.eu-west-2.amazonaws.com/ModelZoo/Compiled/v2.9.0/yolov8m.hef'


WEIGHTS_FOLDER = 'hailo8'
WEIGHT_FILES = ["common_objects_yolov8m_hailo8_640.hef"]
THRESHOLD = 0.3


IMAGE_FILE_TYPES = ['jpg','JPG','jpeg','png','PNG']


HAILO_INTERFACE = HailoStreamInterface.PCIe

######################################

#REF: 'https://docs.ultralytics.com/integrations/hailo#step-3-run-inference'
#REF: 'https://community.hailo.ai/t/detection-and-tracking-in-real-time-using-the-python-api/4863/4'
#REF: 'https://community.hailo.ai/t/hailort-minimal-working-example-for-python-and-hailo8/7685'
#REF: 'https://community.hailo.ai/t/looking-for-a-solution-to-yolov8n-yolov8-nms-postprocess-related-errors/6269'
#REF: 'https://docs.degirum.com/pysdk/release-notes'
#REF: 'https://github.com/hailo-ai/hailo-apps/issues/91'

def get_files(folder_path):
    img_files = []
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


def check_for_device():
    device = None
    try:
        # Scan for all available Hailo devices
        discovered_devices = Device.scan()
        
        if not discovered_devices:
            print("No Hailo devices found. Check your hardware connection or PCIe drivers.")
        else:
            print(f"Found {len(discovered_devices)} Hailo device(s):")
            for idx, device_id in enumerate(discovered_devices, start=1):
                print(f"  [{idx}] Device ID / PCIe Address: {device_id}")
            device = device_id
                
    except HailoRTStatusException as e:
        print(f"Error communicating with the Hailo interface: {e}")
    except ModuleNotFoundError:
        print("The 'hailo_platform' module is not installed. Please install pyHailoRT.")
    return device


def preprocess_image(cv2_img,input_shape):
        input_data = None
        ###################
        # Preprocess Image Data
        if cv2_img is None:
            print("Failed to import img file " + str(image_file))
        else:
            if is_gray(cv2_img):
                img_rgb = cv2.cvtColor(cv2_img, cv2.COLOR_GRAY2RGB)
            else:
                img_rgb = cv2.cvtColor(cv2_img, cv2.COLOR_BGR2RGB)

            h, w, c = img_rgb.shape

            # Get expected model input dimensions
            input_height, input_width = input_shape[0], input_shape[1]

            # Resize image to match model input and normalize (if required by your pre-processing)
            cv2_img_shape = cv2_img.shape
            cv2_img_width = cv2_img_shape[1]
            cv2_img_height = cv2_img_shape[0]
            # print("Got image to w/h: " + str([cv2_img_width,cv2_img_height]))
            # print("Resizing image to w/h: " + str([input_width,input_height]))
            resized_image = cv2.resize(img_rgb, (input_width, input_height), interpolation=cv2.INTER_LINEAR)
            
            # Normalize the image (typically [0, 255] -> [0, 1] or [-1, 1] depending on your HEF model)
            #input_data = resized_image.astype(np.float32) / 255.0 

            input_data = {input_vstream_info.name: np.expand_dims(resized_image, axis=0).astype(np.uint8)} 

            # Add batch dimension: shape becomes (1, height, width, channels)
            

        return input_data


def process_results(cv2_img, input_shape, results):
    ######################
    cv2_img_shape = cv2_img.shape
    cv2_img_width = cv2_img_shape[1]
    cv2_img_height = cv2_img_shape[0]
    cv2_img_area = cv2_img_shape[0] * cv2_img_shape[1]


    detect_dict_list = []
    for class_id, class_detections in enumerate(results[list(results.keys())[0]][0]):
        if class_detections.shape[0]>0:

            for detection in class_detections:
                if len(detection) >= 5:
                    if detection[4] > THRESHOLD:
           

                        det_name = "class_" + str(class_id) #### NEED TO GET CLASS NAMES FROM YAML
                        det_id = class_id
                        det_prob = round(detection[4].item(), 5)
                        [ymin, xmin, ymax, xmax] = detection[:4]

                        # Convert to pixel coordinates relative to the original image
                        oh, ow, _ = np.asarray(cv2_img).shape
                        rh, rw = oh/input_shape[0], ow/input_shape[1]
                        abs_ymin = int(ymin * oh)
                        abs_xmin = int(xmin * ow)
                        abs_ymax = int(ymax * oh)
                        abs_xmax = int(xmax * ow)

                        det_area = (abs_xmax - abs_xmin) * (abs_ymax - abs_ymin)
                        detect_dict = {
                            'name': det_name,
                            'id': det_id,
                            'uid': '',
                            'prob': det_prob,
                            'xmin': abs_xmin,
                            'ymin': abs_ymin,
                            'xmax': abs_xmax,
                            'ymax': abs_ymax,
                            'area_pixels': int(det_area),
                            'area_ratio': det_area / cv2_img_area
                        }
                        detect_dict_list.append(detect_dict)
    return detect_dict_list





            
######################################
if __name__ == '__main__':



    device = check_for_device()
    if device is not None:
        # # Load model config from yaml
        # yaml_path = os.path.join(script_dir, YAML_FILE)
        # print('')
        # print("Loading model config: " + str(yaml_path))
        # with open(yaml_path, 'r') as f:
        #     yaml_dict = yaml.safe_load(f)
        # model_info = yaml_dict['ai_model']
        # classes = model_info['classes']['names']
        # proc_img_width = model_info['image_size']['image_width']['value']
        # proc_img_height = model_info['image_size']['image_height']['value']
        # print("Classes: " + str(len(classes)))
        # print("Process size: " + str(proc_img_width) + "x" + str(proc_img_height))

        print('')
        print("Getting test images from: " + str(IMAGES_DIR))

        image_files = get_files(IMAGES_DIR)
        num_files = len(image_files)

        if num_files == 0:
            print("No images found at: " + str(IMAGES_DIR))
        else:
            print("Found " + str(num_files) + " images")

            device = VDevice()

            weights_path = os.path.join(script_dir, WEIGHTS_FOLDER)
            for weight_file in WEIGHT_FILES:
                print("########################")
                print("Testing model file " + str(weight_file))
                print("########################")
                ######################################
                # Load Model
                weight_file_path = os.path.join(weights_path, weight_file)
                print('')
                print("Loading HEF model: " + str(weight_file_path))

                hef = HEF(weight_file_path)
                input_infos = hef.get_input_vstream_infos()
                print(f"--- Found {len(input_infos)} Input Stream(s) ---")
                print(input_infos)

                # 3. Extract output stream parameters 
                output_infos = hef.get_output_vstream_infos()
                print(f"--- Found {len(output_infos)} Output Stream(s) ---")
                print(output_infos)

    
                
                # Configure the network group
                configure_params = None
                network_groups = None
                network_group = None
                network_group_params = None
                try:
                    configure_params = ConfigureParams.create_from_hef(hef, interface=HAILO_INTERFACE)
                    network_group = device.configure(hef, configure_params)[0]
                    network_group_params = network_group.create_params()
                except Exception as e:
                    print("Device config failed with error: " + str(e))
                if configure_params is not None and network_group_params is not None:
                    print("Got network config: " + str(network_group_params))
                    # Get stream info for input/output naming
                    input_vstream_info = hef.get_input_vstream_infos()[0]
                    input_vstreams_params = InputVStreamParams.make_from_network_group(network_group, quantized=False, format_type=FormatType.UINT8)
                    print("")
                    print("input_vstream_info " + str(input_vstreams_params))
                    
                    output_vstreams_params = OutputVStreamParams.make_from_network_group(network_group, quantized=False, format_type=FormatType.FLOAT32)
                    print("")
                    print("output_vstreams_params " + str(output_vstreams_params))
                    print("")
                    # Build vstream params

                    ###########################
                    # Prime the Model
                   

                    random_int = random.randint(1, num_files)-1
                    image_file = os.path.join(IMAGES_DIR, image_files[random_int])
                    cv2_img = cv2.imread(image_file)
                    

                    ###################
                    results = None
                    input_info = hef.get_input_stream_infos()[0]
                    input_shape = input_info.shape
                    print(input_info)
                    print(input_shape)

                    input_data=preprocess_image(cv2_img,input_shape)
                    if input_data is not None:
                        print('')
                        print("Priming the Model")
                        results = None
                        try:
                            with InferVStreams(network_group, input_vstreams_params, output_vstreams_params) as infer_pipeline:   
                                        with network_group.activate(network_group_params):
                                            results = infer_pipeline.infer(input_data)

                        except Exception as e:
                            print("Failed to process detection with exception: " + str(e))


                    detect_dict_list = None
                    if results is not None:
                        print("Inference completed successfully!")
                        # You can now parse `results` using your specific model's post-processing logic
                        detect_dict_list = process_results(cv2_img, input_shape, results)
                        print("Got Detect Dict List")
                        print(detect_dict_list)



                    if detect_dict_list is not None:

                        ###########################
                        # Run Tests
                        print('')
                        print("Running Detection Speed Test with " + str(NUM_TESTS) + " Detections")
                        
                        elapsed_time = 0
                        
                        for i in range(1, NUM_TESTS):
                            
                            random_int = random.randint(1, num_files)-1
                            image_file = os.path.join(IMAGES_DIR, image_files[random_int])
                            cv2_img = cv2.imread(image_file)

                            start_time = time.time()

                            input_data=preprocess_image(cv2_img,input_shape)
                            if input_data is not None:
                                results = None
                                try:
                                    with InferVStreams(network_group, input_vstreams_params, output_vstreams_params) as infer_pipeline:   
                                                with network_group.activate(network_group_params):
                                                    results = infer_pipeline.infer(input_data)
                                except Exception as e:
                                    print("Failed to process detection with exception: " + str(e))


                            end_time = time.time()

                            detect_time = end_time - start_time
                            elapsed_time = elapsed_time + detect_time

                        if results is None:
                            print("FAIL TO GET RESULTS FROM DETECTION PROCESS")
                        else:

                                print("Got detect dict list: " + str(detect_dict_list))

                                drate = float(1.0) / elapsed_time * NUM_TESTS
                                print("")
                                print("")
                                print(f"Ran {NUM_TESTS} detections in: {elapsed_time:.6f} seconds")
                                print(f"Average detection rate: {drate:.2f} hz")

            device.release()