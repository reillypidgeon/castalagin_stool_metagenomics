# Globus Command Line Interface (CLI) Tutorial for ENA PRJEB76307
## Installing Globus CLI
Copied from the [DRAC documentation on the Globus CLI](https://docs.alliancecan.ca/wiki/Globus#Command_line_interface_(CLI)). In the login node (of Narval in this case), run the following:
```
virtualenv $HOME/.globus-cli-virtualenv
source $HOME/.globus-cli-virtualenv/bin/activate
pip install globus-cli
deactivate
export PATH=$PATH:$HOME/.globus-cli-virtualenv/bin
echo 'export PATH=$PATH:$HOME/.globus-cli-virtualenv/bin'>>$HOME/.bashrc
```
## Setting Up the Downloads
Now that the Globus CLI is installed, we can follow the [CLI QuickStart Guide](https://docs.globus.org/cli/quickstart/) and [Globus Transfer](https://docs.globus.org/cli/reference/transfer/) tutorials.
```
globus login
```
You will need to authenticate with Globus by pasting the printed link into your browser, logging into your DRAC account, and entering the Authorization Code in the command line. <br>
You now need to `export` variables relating to endpoint IDs for the Globus Collections you want to use for data transfers.
These IDs (UUID) can be found using the following commands:
```
# Looking for the ID (UUID) for Display Name: Compute Canada - Narval
globus endpoint search "Narval"

# Looking for the ID (UUID) for Display Name: EMBL-EBI Public Data
globus endpoint search "EMBL"
```
Now, these IDs can be assigned to variables. The IDs below are taken from the [Globus Transfer](https://docs.globus.org/cli/reference/transfer/) tutorial. Replace these with your actual IDs based on the code above.
```
# Replace the IDs with the ones obtained using the globus endpoint search commands above
export cluster="aa752cea-8222-5bc8-acd9-555b090c0ccb"
export embl="313ce13e-b597-5858-ae13-29e46fea26e6"
```
You can now use commands like `globus ls` and `globus transfer`. For example, you can list the contents of the `$embl` variable (EMBL-EBI Public Data)
```
globus ls $embl
```
Which outputs:
```
1000g/
bioimaging/
biostudies/
empiar/
ensemblgenomes/
ensemblorg/
faang/
hipsci/
pride/
pride-archive/
pub/
vol1/
```
The first time you try to access Narval using `globus ls $narval`, you will need to authenticate again by following the printed instructions. Once done, you should be able to see the contents of your home directory.
```
globus ls $cluster
```
You can now access your `scratch` directory:
```
globus ls $cluster:scratch
```
Make sure the `castalagin_stool_metagenomics` repository is cloned in your `$SCRATCH` directory.
```
git clone https://github.com/reillypidgeon/castalagin_stool_metagenomics.git
```
At this point, the tool is set up and files can be transferred between EMBL-EBI Public data and the cluster (Compute Canada - Narval). Make sure to replace the Globus UUID variables with your actual UUIDs before running the code below.
```
# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
mkdir -p "${project_dir}"

scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics"

urls_file="${scripts_dir}/ena_PRJEB76307_urls.txt"

# Create a directory for all raw reads data in the scratch directory
read_dir="${project_dir}/raw_reads"
mkdir -p "${read_dir}"

# Export the globus UUIDs if not already done
export cluster="aa752cea-8222-5bc8-acd9-555b090c0ccb" # Replace with real UUID
export embl="313ce13e-b597-5858-ae13-29e46fea26e6" # Replace with real UUID
#===========================================================================

# Remove urls that have already been downloaded and processed
urls_file_to_download="${scripts_dir}/ena_PRJEB76307_urls_to_download.txt"
> "${urls_file_to_download}"

while IFS= read -r line; do
    subject_id=$(echo $line | grep -Eo "0[0-9]{2}_V[1-4]")
    new_file_name=$(echo $line | grep -Eo "0[0-9]{2}_V[1-4]_R[1-2]\.fastq\.gz")
    processed_file="${subject_id}/${new_file_name}"
    
    if [[ -f "${processed_file}" ]]; then
        echo "File ${new_file_name} has already been processed. Skipping..."
        continue
    else
        echo "Adding ${new_file_name} to the list of URLs to download"
    fi
    echo "$line" >> "${urls_file_to_download}"
done < "${urls_file}"

echo "Starting download of PRJEB76307 sequencing reads"

if [[ ! -s "${urls_file_to_download}" ]]; then
    echo "Nothing to download."
    exit 0
fi

# Create a batch file for the Globus CLI tool using the $urls_file for all files that have not yet been downloaded and processed
while IFS= read -r line; do
    embl_path=$(echo "$line" | grep -Eo "vol1/run/ERR132/[^ ]*")
    file_name=$(basename ${embl_path})
    batch_line="${embl_path} ${read_dir}/${file_name}"
    echo "${batch_line}" >> "${scripts_dir}/ena_PRJEB76307_globus_batch.txt"
done < "${urls_file_to_download}"

# Download the raw sequencing reads from Globus
globus transfer $embl $cluster --batch ${scripts_dir}/ena_PRJEB76307_globus_batch.txt

echo "Finished downloading reads"
```
You can check on the status of a transfer using:
```
globus task show <TASK_ID>
```
Once the reads are done downloading, you can run the ena_PRJEB76307_setup.slurm script (in castalagin_stool_metagenomics/PRJEB76307_metagenomics/)
```
# Submit a scheduled job for FASTQ renaming and transfer to directories by sample ID
echo "Submitting scheduled job to set up FASTQ files for array jobs"
sbatch "${scripts_dir}/ena_PRJEB76307_setup.slurm"
```
After all these steps, you should have 66 directories containing read sets (R1 and R2) for a total of 132 files!
