#!/usr/bin/python3

import os
import yaml
import gnupg
from datetime import datetime
import fcntl
import socket
import struct
import asyncio
import websockets
import random

NEPI_LICENSE_FOLDER = '/mnt/nepi_storage/license'
NEPI_LICENSE_BASENAME = NEPI_LICENSE_FOLDER + '/nepi_license_'
NEPI_LICENSE_EXTENSION = '.gpg'
NEPI_LICENSE_REQUEST_BASENAME = NEPI_LICENSE_FOLDER + '/nepi_license_request_'
NEPI_LICENSE_REQUEST_EXTENSION = '.yaml'
NEPI_GPG_KEYPATH = '/home/nepi/.gnupg'
NEPI_VERSION_FILE = '/opt/nepi/nepi_engine/etc/fw_version.txt'

LICENSE_WARNING_FILE = '/opt/nepi/etc/license/UNLICENSED_NEPI_ENGINE.txt'
UNLICENSED_LICENSE_DICT = {'licensed_components':{'nepi_base':{'commercial_license_type': 'Unlicensed'}}}


NEPI_CONFIG_FILE = '/opt/nepi/etc/nepi_system_config.yaml'

HARDWARE_ID=""

def read_dict_from_file(file_path):
    dict_from_file = None
    if os.path.exists(file_path):
        try:
            with open(file_path) as f:
                dict_from_file = yaml.load(f, Loader=yaml.FullLoader)
        except Exception as e:
            print("Failed to get dict from file: " + file_path + " " + str(e))
    else:
        print("Failed to find dict file: " + file_path)
    return dict_from_file


def getHardwareId():
        NEPI_WIRED_INTERFACE = 'eth0'
        NEPI_CONFIG_DICT=read_dict_from_file(NEPI_CONFIG_FILE)
        #print("Got NEPI CONFIG Dict: " + str(NEPI_CONFIG_DICT))
        if NEPI_CONFIG_DICT is not None:
            if "NEPI_WIRED_INTERFACE" in NEPI_CONFIG_DICT.keys():
                wif = NEPI_CONFIG_DICT['NEPI_WIRED_INTERFACE']
                if wif is not None:
                    if wif != "":
                        NEPI_WIRED_INTERFACE=wif
                        #print("Got network interface id: " + str(wif))
        #print("Using network interface id: " + str(NEPI_WIRED_INTERFACE))
        
        
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        info = fcntl.ioctl(s.fileno(), 0x8927,  struct.pack('256s', bytes(NEPI_WIRED_INTERFACE, 'utf-8')[:15]))
        hardware_id = ''.join('%02x' % b for b in info[18:24])
        print("Got Hardware ID: " + str(hardware_id) + " for network interface id: " + str(NEPI_WIRED_INTERFACE))
        global HARDWARE_ID
        HARDWARE_ID=hardware_id
        return hardware_id

def getNEPIVersion():
    if not os.path.exists(NEPI_VERSION_FILE):
        raise Exception("Unable to determine NEPI version from file " + NEPI_VERSION_FILE)
    with open(NEPI_VERSION_FILE, 'r') as f:
        return f.readline()

def checkLicense():
    try:
        detected_key = HARDWARE_ID #getHardwareId()
        license_fullpath = NEPI_LICENSE_BASENAME + detected_key + NEPI_LICENSE_EXTENSION
        if not os.path.exists(license_fullpath):
            raise Exception("License file not found: " + license_fullpath)

        gpg = gnupg.GPG(gnupghome=NEPI_GPG_KEYPATH)
        
        license_text = ''
        with open(license_fullpath, 'rb') as license_file:
            license_obj = gpg.decrypt_file(license_file, always_trust=True, extra_args=['--ignore-time-conflict'])
            print('ok:' + str(license_obj.ok) + ", status: " + license_obj.status + ", stderr: " + license_obj.stderr)
            if (not license_obj.ok):
                if (license_obj.status != "signature valid"):
                    raise Exception("License decrypt failed: " + license_obj.status)
            license_text = str(license_obj)

        license_contents = yaml.load(license_text)
        
        if ('licensed_components' not in license_contents) or ('nepi_base' not in license_contents['licensed_components']):
            raise Exception("Bad format")
        
        nb_license_contents = license_contents['licensed_components']['nepi_base']
        
        if ('hardware_key' not in nb_license_contents):
            raise Exception("Missing h/w key")
        
        if detected_key != nb_license_contents['hardware_key']:
            raise Exception("H/W key mismatch")
        
        if ('commercial_license_type' not in nb_license_contents):
            raise Exception("Missing lic. type")
                
        now = datetime.now()
        if ('expiration_date' in nb_license_contents):
            print("Debug: expiration_date = " + nb_license_contents['expiration_date'])
            expiration = datetime.strptime(nb_license_contents['expiration_date'], '%m/%d/%Y')
            if (now > expiration):
                raise Exception('Expired: ' + nb_license_contents['expiration_date'])
        if ('expiration_version' in nb_license_contents):
            version_parts = getNEPIVersion().split('.')
            if len(version_parts) < 3:
                raise Exception("Bad f/w version format")
                            
            expiration_parts = nb_license_contents['expiration_version'].split('.')
            if len(expiration_parts) < 3:
                raise Exception("Bad lic. expiration version format")
            
            print("Debug: " + str(version_parts) + ", " + str(expiration_parts))
            
            if (version_parts[0] >= expiration_parts[0]) or \
            ((version_parts[0] == expiration_parts[0]) and (version_parts[1] > expiration_parts[1])) or \
            ((version_parts[0] == expiration_parts[0]) and (version_parts[1] == expiration_parts[1]) and (version_parts[1] >= expiration_parts[1])):
                raise Exception('Expired: ' + nb_license_contents['expiration_version'])
                
        if os.path.exists(LICENSE_WARNING_FILE):
            os.remove(LICENSE_WARNING_FILE)
        license_contents['licensed_components']['nepi_base']['status'] = 'Valid'
        print("Debug: License valid: " + str(license_contents))
        return yaml.dump(license_contents)

    except Exception as e:
        with open(LICENSE_WARNING_FILE, 'w') as f:
            f.write("THIS DEVICE IS RUNNING AN UNLICENSED VERSION OF NEPI.\n")
            f.write("-----------------------------------------------------------------------------------\n")
            f.write("Failed to validate commercial license: " + str(e) + "\n")
            #print("Debug: " + str(e))
        exception_license = UNLICENSED_LICENSE_DICT.copy()
        exception_license['licensed_components']['nepi_base']['status'] = str(e)
        #print("Debug: License invalid: " + str(e))
        return yaml.dump(exception_license)

def generateLicenseRequest():
    hardware_id = HARDWARE_ID #getHardwareId()
    date = datetime.now().strftime("%m/%d/%Y")
    version = getNEPIVersion()
    request_yaml = "license_request:\n" + "  hardware_key: " + hardware_id + "\n  date: " + date + "\n  version: " + version + \
                   "  instructions: To request a commercial license, email this file to nepi@numurus.com"
    #print("License Request: Created license request " + request_yaml)
    if not os.path.exists(NEPI_LICENSE_FOLDER):
        print("License Request: Will create license folder at " + NEPI_LICENSE_FOLDER)
        os.mkdir(NEPI_LICENSE_FOLDER, mode=775)

    try:
        detected_key = getHardwareId()
    except:
        detected_key = '_BAD_HARDWARE_ID'

    request_file_full_path = NEPI_LICENSE_REQUEST_BASENAME + detected_key + NEPI_LICENSE_REQUEST_EXTENSION
    #print("License Request: Creating license request file at " + request_file_full_path)
    with open(request_file_full_path, 'w') as f:
        f.write(request_yaml)

    return request_yaml

async def handleRequests(websocket, path):
    while True:
        #print("Will try to recieve on websocket 9092")
        try:
            request = await websocket.recv()
            message = ""
            if request == "license_check":
                message = checkLicense()
            elif request == "license_request":
                message = generateLicenseRequest()
                #print("Debug: Responding with " + message)
            else:
                message = "request: unknown"
        except Exception as e:
            #print("Socket request failed")
            message = "failed: " + str(e)
        #print("Will try to send message " + str(message))
        try:
            await websocket.send(message)
            #print("Socket send succeeded")
        except:
            #print("Socket send failed")
            pass
        #print("Sleeping")
        await asyncio.sleep(random.random() * 2 + 1)

async def serverMain():
    print('Launching server')
    print("Will try to recieve on websocket 9092")
    async with websockets.serve(handleRequests, "0.0.0.0", 9092):
        #print("Waiting for server handler")
        await asyncio.Future()

if __name__ == "__main__":
    print('Getting Hardware ID')
    hardware_id=getHardwareId()
    print("Starting with Hardware ID: " + str(HARDWARE_ID))
    print('Testing License Check')
    license_info = checkLicense()
    print('Got License Info: ' + str(license_info))
    print('Creating Async Loop')
    loop = asyncio.get_event_loop()
    print('Starting nepi license server')
    result = loop.run_until_complete(serverMain())
    



