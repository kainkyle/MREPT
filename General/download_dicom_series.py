import flywheel
import pydicom
import sys
import os
import zipfile
import os, fnmatch

session_label = sys.argv[1]
download_directory = sys.argv[2]
series_description = sys.argv[3]
download_name = sys.argv[4]

fw = flywheel.Client()

print(f"Searching for session {session_label}")

filter_ = 'label=' + '"' +  session_label +  '"'
sessions = fw.sessions.find(filter_)

if len(sessions) == 1:
    session = sessions[0]
    subject = session.subject.label
else:
    print(f'{len(sessions)} sessions found. Check session label')
    exit()



acquisition_filter = 'label=' + '"' +  series_description +  '"'

acquisitions = session.acquisitions.find(acquisition_filter)

print(f" {len(acquisitions)} acquisitions found")

for acq in acquisitions:
    for file in acq.files:
        if file.type == 'dicom':
            f = file.reload()
            file_name = file.name
            try:
                # image_type = str(f.info['ImageType'])
                series_number = f.info['SeriesNumber']
                instance_number = str(f.info['InstanceNumber'])
                series_desc = f.info['SeriesDescription']
                study_date = str(f.info['StudyDate'])
                dicom_download_name = '_'.join([series_desc,instance_number]) + '.dcm'
                final_download_dir = os.path.join(download_directory,study_date,'DICOM',download_name)
                if not os.path.isdir(final_download_dir):
                    os.makedirs(final_download_dir, exist_ok=True)
                download_file_name = os.path.join(final_download_dir,dicom_download_name)
                acq.download_file(file_name,download_file_name)
                print('Downloaded: ' + str(download_file_name))
                
                
                # Test if downloaded file is zipped

                dcm_is_zipped =  zipfile.is_zipfile(download_file_name)
                
                
                if dcm_is_zipped == True:
                    print('Zipped file found')
                    with zipfile.ZipFile(download_file_name, 'r') as zip_ref:
                        zip_ref.extractall(final_download_dir)
                    os.remove(download_file_name)
                
                
            except:
                print('Skipping File: ' + str(file_name))
