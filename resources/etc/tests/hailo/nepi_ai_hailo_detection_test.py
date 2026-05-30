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

from hailo_platform import (
    HEF, VDevice, HailoStreamInterface, InferVStreams,
    ConfigureParams, InputVStreamParams, OutputVStreamParams, FormatType
)


# Get the path of the current script file
script_dir = os.path.dirname(__file__)


NUM_TESTS = 100
IMAGES_DIR = os.path.join(script_dir, '..', 'images')
WEIGHT_FILE = "yolov8m.hef"
YAML_FILE = "common_objects_yolov8m_hailo_640.yaml"
THRESHOLD = 0.3


IMAGE_FILE_TYPES = ['jpg','JPG','jpeg','png','PNG']

######################################


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


######################################
if __name__ == '__main__':

    # Load model config from yaml
    yaml_path = os.path.join(script_dir, YAML_FILE)
    print('')
    print("Loading model config: " + str(yaml_path))
    with open(yaml_path, 'r') as f:
        yaml_dict = yaml.safe_load(f)
    model_info = yaml_dict['ai_model']
    classes = model_info['classes']['names']
    proc_img_width = model_info['image_size']['image_width']['value']
    proc_img_height = model_info['image_size']['image_height']['value']
    print("Classes: " + str(len(classes)))
    print("Process size: " + str(proc_img_width) + "x" + str(proc_img_height))

    print('')
    print("Getting test images from: " + str(IMAGES_DIR))

    image_files = get_files(IMAGES_DIR)
    num_files = len(image_files)

    if num_files == 0:
        print("No images found at: " + str(IMAGES_DIR))
    else:
        print("Found " + str(num_files) + " images")

        ######################################
        # Load Model
        weight_file_path = os.path.join(script_dir, WEIGHT_FILE)
        print('')
        print("Loading HEF model: " + str(weight_file_path))

        hef = HEF(weight_file_path)
        target = VDevice()
        configure_params = ConfigureParams.create_from_hef(hef, interface=HailoStreamInterface.PCIe)
        network_groups = target.configure(hef, configure_params)
        network_group = network_groups[0]
        network_group_params = network_group.create_params()

        input_info = hef.get_input_vstream_infos()[0]
        input_name = input_info.name
        input_height = input_info.shape[0]
        input_width = input_info.shape[1]
        print("Model input shape: " + str(input_width) + "x" + str(input_height))

        input_vstream_params = InputVStreamParams.make(network_group, format_type=FormatType.FLOAT32)
        output_vstream_params = OutputVStreamParams.make(network_group, format_type=FormatType.FLOAT32)

        ###########################
        # Prime the Model
        results = None
        raw_detections = None

        random_int = random.randint(1, num_files)-1
        image_file = os.path.join(IMAGES_DIR, image_files[random_int])
        cv2_img = cv2.imread(image_file)
        if cv2_img is None:
            print("Failed to import img file " + str(image_file))
        else:
            if is_gray(cv2_img):
                cv2_img = cv2.cvtColor(cv2_img, cv2.COLOR_GRAY2BGR)
            else:
                cv2_img = cv2.cvtColor(cv2_img, cv2.COLOR_BGR2RGB)

            input_img = cv2.resize(cv2_img, (input_width, input_height)).astype(np.float32) / 255.0
            input_data = {input_name: np.expand_dims(input_img, axis=0)}

            print('')
            print("Priming the Model")
            try:
                with InferVStreams(network_group, input_vstream_params, output_vstream_params) as infer_pipeline:
                    with network_group.activate(network_group_params):
                        raw_detections = infer_pipeline.infer(input_data)
            except Exception as e:
                print("Failed to process detection with exception: " + str(e))

            ###########################
            # Run Tests
            print('')
            print("Running Detection Speed Test with " + str(NUM_TESTS) + " Detections")
            elapsed_time = 0
            for i in range(1, NUM_TESTS):

                random_int = random.randint(1, num_files)-1
                image_file = os.path.join(IMAGES_DIR, image_files[random_int])
                cv2_img = cv2.imread(image_file)
                if cv2_img is None:
                    print("Failed to import img file " + str(image_file))
                else:
                    if is_gray(cv2_img):
                        cv2_img = cv2.cvtColor(cv2_img, cv2.COLOR_GRAY2BGR)
                    else:
                        cv2_img = cv2.cvtColor(cv2_img, cv2.COLOR_BGR2RGB)

                    input_img = cv2.resize(cv2_img, (input_width, input_height)).astype(np.float32) / 255.0
                    input_data = {input_name: np.expand_dims(input_img, axis=0)}

                    start_time = time.time()
                    try:
                        # Inference
                        with InferVStreams(network_group, input_vstream_params, output_vstream_params) as infer_pipeline:
                            with network_group.activate(network_group_params):
                                raw_detections = infer_pipeline.infer(input_data)
                    except Exception as e:
                        print("Failed to process detection with exception: " + str(e))
                    end_time = time.time()

                    detect_time = end_time - start_time
                    elapsed_time = elapsed_time + detect_time

            if raw_detections is None:
                print("FAIL TO GET RESULTS FROM DETECTION PROCESS")
            else:
                ######################
                # Print Results
                cv2_img_shape = cv2_img.shape
                cv2_img_width = cv2_img_shape[1]
                cv2_img_height = cv2_img_shape[0]
                cv2_img_area = cv2_img_shape[0] * cv2_img_shape[1]

                output_name = list(raw_detections.keys())[0]
                detections = raw_detections[output_name][0]

                detect_dict_list = []
                for det in detections:
                    print(det)
                    det_prob = float(det[4])
                    if det_prob < THRESHOLD:
                        continue
                    det_id = int(det[5])
                    if det_id >= len(classes):
                        continue
                    det_name = classes[det_id]
                    xmin = int(det[0] * cv2_img_width / input_width)
                    ymin = int(det[1] * cv2_img_height / input_height)
                    xmax = int(det[2] * cv2_img_width / input_width)
                    ymax = int(det[3] * cv2_img_height / input_height)
                    det_area = (xmax - xmin) * (ymax - ymin)
                    detect_dict = {
                        'name': det_name,
                        'id': det_id,
                        'uid': '',
                        'prob': det_prob,
                        'xmin': xmin,
                        'ymin': ymin,
                        'xmax': xmax,
                        'ymax': ymax,
                        'area_pixels': int(det_area),
                        'area_ratio': det_area / cv2_img_area
                    }
                    detect_dict_list.append(detect_dict)

                print("Got detect dict list: " + str(detect_dict_list))

                drate = float(1.0) / elapsed_time * NUM_TESTS
                print("")
                print("")
                print(f"Ran {NUM_TESTS} detections in: {elapsed_time:.6f} seconds")
                print(f"Average detection rate: {drate:.2f} hz")