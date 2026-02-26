import shutil

# Lambda function to zip the source code directory without the .py extension
output_filename = "retrieveVisitorCountPython"

archive_format = "zip"

source_dir = "/Users/aaaa/Code/CloudResumeChallenge"

shutil.make_archive(output_filename, archive_format, source_dir)

print(f"Successfully created {output_filename}.zip")