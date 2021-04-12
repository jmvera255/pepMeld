# pepMeld Overview

pepMeld is a configurable, open-source pipeline designed to work with data generated by Peptide Microarray instrumentation.
A peptide Microarray is collection of hundreds to millions of peptide chains anchored to a substrate.
An instruments Peptide Microarray Instrumentation can analyze the pepptide chips to study binding properties and protein-protein interactions.  
THey have been used to study and profile insitu protein interections of allergens, antibody response to viruses and enzyme functionality.
 
pepMeld can aggregate, normalize, and applies quality assurance checks and qualtiy assurance filters to peptide microarray data.
Peptide Microarray data can be overwhelming and dificult to process and understand.  
Our goal is to aid in the data processing and reduce the data to a form ready for analysis and charting with open source tools.


# Quickstart
## Installation
pepMeld was designed for MacOS (10 and Later) or Ubuntu 16, 18 and 20 Operating systems (untested on Windows Operating systems).  
There are two primary ways to install and use pepMeld: Docker and copying the files and pointing to the repository.

Installing by creating and launching Docker image is the preferred installation method. This installation ensures the prerequisite packages and python is properly installed with the correct version.


Copying the files and launching is an easy way to run the data, however, you may run into version issues, and missing packages.

### Installing wth docker
1. Download the github repository (instructions assume it is downloaded to ~/)
2. Uncompress as needed.
3. Ensure docker is running on your local machine
4. Change directories to the ~/pepMeld/pepmeld_docker repository
5. Create a docker image
```bash
# you can add your own tag here
image_tag=v1 
# set your path to data here
path_to_data_and_config_dir=<path_to_data_and_config_dir> 
# set the number of cores to dedicate to your image here.  pepMeld uses threading and can take advantage of multi-core processing
cores=2 
cd ~/
tar -xzvf pepMeld.tar.gz
cd ~/pepMeld/pepMeld_docker
docker build -t pepmeld:${image_tag} .
docker run --cpus ${cores} -it -v ${path_to_data_and_config_dir}>:/scratch pepmeld:${image_tag}
# In the docker image create an output directory that matches your configuration
mkdir -p /scratch/out
mkdir -p /scratch/out_charts
# set transforms_path to the path or your transforms pipeline JSON file.
python /pepMeld/process_arrays.py --transforms_path=/scratch/<pepMeld_transformations.json>
```

### Installing from repository
1. Download the github repository (instructions assumes repository is downloaded as tar.gz to ~/ [/home/<username>/ or /Users/<username>/])
2. Uncompress as needed.

```bash
# scipy
# sklearn
# matplotlib
# statsmodels
# seaborn>=0.10.0
# pandas
# Add the requirements you are missing 
pip install <requirements> 
cd ~/
tar -xzvf pepMeld.tar.gz
python ~/pepMeld/process_arrays.py --transforms_path=/scratch/<pepMeld_transformations.json>

```

# Editing the transformations pipeline JSON file
- The pipeline can be reorded and restructured as needed based on your input data.
- If your data is missing items such as physical location of peptide, then those steps should be skipped
- Each input/output, and transfromation is a different step in the transformations pipeline JSON file
    - "order" (required) is the step order delared. Decimals are allowed (i.e. 1 or 1.1).  Pipeline runs in this order, not the order they appear in pipeline file   
    - "name" (required) is a name you give the step. Each step must have a unique name. Recommend using less than 140 characters, and no special characters, (underscore and . is okay). 
    - "skip" (optional, default: true): set to false if you want the step skipped.
    - "transformation_func" (required) is the name of each pipeline step class (case sensitive) in the python code
    - 'transformation_args" (required) is a dictionary with the key being the argument of the class name, and value being the value assigned to the corresponding argument.
##  Example Configuration Step
 ```json

 {"name" : "Merge Stack Meta data and stacked_all_seq_except_wi",
		"order" : 10.1,
		"skip" : true,
		"transformation_func":"merge_data_frames",
		"transformation_args" : {
			"df_name_left":"corr_all_seq_except_wi",			
			"df_name_right":"stacked",
			"df_out" : "corr_all_seq_except_wi",
			"how" : "inner"
}
 ```
# Tranformation Pipeline Classes:
## open_data_meta_files
 - data_filepaths (required, list []) list of filepaths to the data files that join directly to meta data.
    - Each data files are required to have:
        - PROBE_SEQUENCE (character) Often single letter per amino acid, can be duplicated on the array
        - <Unique Sample Name> Intensity Data Column for each sample (float) 
            - Must be Uniquely named
            - May be a name that can be looked up from the metadata table
    - Optional Columns
        - X The physical X coordinate the peptide lawn resides on the array, X and Y are BOTH required for spatial quality assurance analysis and filtering
        - Y The physical Y coordinate the peptide lawn resides on the array, X and Y are BOTH required for spatial quality assurance analysis and filtering
        - PEP_LEN The amino acid count of a peptide chain.
        - REPL If the probe sequence is replicated on the array this is the replicate number 
    
- meta_filepaths (optional, list []) list of your metadata filepaths
    - Each metadata file must have:
        - VENDOR_NAME (character) a unique name given by the vendor. it must match the data file column name
        - SAMPLE_NAME (character) a unique name for each sample that is human readable.  Can be the same as the vendor name.
        - SAMPLE_NUMBER (integer) a unique number given to each sample, cannot contain same number across metadata files.
    - Optional metadata for each sample, (i.e. age, Days post infection etc.)
        - Special Columns:
            -Subtract columns (optional) matches the combination of SAMPLE_NAME, location (if provided, X,Y) , and PROBE_SEQUENCE and takes the difference between the sample row and this combination intensity values
                - Each row should have the exact (case-sensitive) column that values need to be subtracted
                - Useful for background subtraction if there is a control sample.
                - Useful for comparing two groups (Control Vs Infected) by providing the difference.
- data_sep (optional (string), default ='\t') this is the separator for the data file.
- meta_sep (optional (string), default =',') this is the separator for the metadata file.
- data_required_descriptor_columns (optional, (dictionary), defualt={'PROBE_SEQUENCE'}),
- meta_required_descriptor_columns (optional, (list), default=['VENDOR_NAME', 'SAMPLE_NUMBER', 'SAMPLE_NAME'])
- sample_name_column (optional, (string), default='SAMPLE_NAME')
- meta_vendor_name_column (optional, (string), default='VENDOR_NAME')
- meta_sample_number_column (optional, (string), default='SAMPLE_NUMBER')
- data_rename_dictionary (optional, dictionary, default={}) meta_filepaths are blank it can use this to translate VENDOR_NAME to  a  SAMPLE_NAME and then dynamically assign a unique SAMPLE_NUMBER
- df_data_in_name (optional, (string), default='df' a name given to the data - DataFrame to be accessed by other steps
- df_meta_in_name (optional, (string), default='meta'a name given to the metadata - DataFrame to be accessed by other steps
### open_data_meta_files example

```json
{
  "name" : "open_data_meta_files",
  "order" : 0.1,
  "transformation_func":"open_data_meta_files",
    "transformation_args" : {
    "data_filepaths": "/scratch/Raw_aggregate_data_igg.txt",
    "data_sep":"\t",
    "meta_filepaths":"/scratch/meta_igg.csv",
    "meta_sep":","
  }
}

```

## open_files

- df_out_name (optional (string), default=df_out_name
- filepaths (required, list []) 
- filepaths (required, string) i.e. '\t', ' ', ',' are the separator used in the file. Header should be first line an only 1 line.
- required_descriptor_columns  (optional, list [])  will force an error if the column sare missing from your file headers.
- keep_columns (optional, list []) These columns will be kept.  Will not force an error if the column is missing
- rename_dictionary (optional, dictionary {}). Used to rename headers as needed.

### example open_files 
```json
{
    "name" : "open_files corr all_seq_except_wi",
    "order" : 10.0,
    "skip" : true,
    "transformation_func":"open_files",
    "transformation_args" : {
        "filepaths" : "/scratch/all_seq_except_wi.tsv.gz",
        "df_out_name" : "corr_all_seq_except_wi",
        "required_descriptor_columns" : ["SEQ_ID","PROBE_SEQUENCE", "POSITION"],
        "keep_columns":["SEQ_ID", "SEQ_NAME", "PROTEIN", "POSITION", "PROBE_SEQUENCE"],
        "rename_dictionary":{"PROBE_SEQUENCE":"PROBE_SEQUENCE", "SEQ_ID":"SEQ_ID", "POSITION":"POSITION", "PROTEIN":"PROTEIN", "SEQ_NAME":"SEQ_NAME"},
    "sep":"\t"
    }
}
```

## save_to_csv
- df_in_name (required, string) input name of DataFrame you want to make into a csv or datafile
- filepath (required, string) filepath of where the csv/data file is saved.
- sep (required, string, default='\t') seperator used (i.e. ',', '\t')
- index (required, boolean, default=false) set to true if you want a numbered index

## merge_data_frames
Merges two DataFrames per Pandas
transformation_name = 'melt_df'
Uses stacked (melted) data

-transformation_name = 'merge_data_frames'
- df_name_left (required, string) df_name_left name of DataFrame
- df_name_right (required, string) df_name_right name of DataFrame
- df_out (required, string) out name of DataFrame
- on_columns =  (optional, list=[], default= all id columns)   
- how (optional, list=[], default='inner)   	   

## melt_class

melts per the melt class in pandas
- df_out_name (required, string) DataFrame output name to be accessed by other transformations
- df_in_name (required, string) DataFrame input name
- value_vars (optional, list, default <all data columns> )
- id_vars (optional, list, default <all id columns>  )
- value_name (optional, string, default ='INTENSITY')
- var_name = (optional, string, SMPLE-NAME)

## log_transform
- base (optional, integer, default=2) the base of the logrithm 
- transform_columns (optional, list=[], default = all data columns if not declared) to only apply to subset of columns. Use samples names from SAMPLE_NAMES 
- df_out_name (required, string) DataFrame output name to be accessed by other transformations
- df_in_name (required, string) DataFrame input name

## find_clusters
Finds the clusters of similar valued (based onhalfway overlapping 5 percentile or what is declared int he 100/percentile _slices) values based on X, Y coordinates
This is due instrumentation/procedure errors due to defects, contamination on the physical substrate, or drips of reagents.
Uses dbscan from sklearn to find the clusters
- df_out_name (required, string) DataFrame output name to be accessed by other transformations
- df_in_name (required, string) DataFrame input name
- df_cluster_name (required, string) Data frame output name
- OUTPUT_CHARTS_DIR (required, string) file path on where the clustering charts end up.
- merge_to_input_df (required, string) data frame
- percentile_slices (optional, positive float, default=20 ) number of slices to use for percentiles. a default of 20 uses 5 percentils slices from 0-5, 2.5-7.5 5-10 ... 92.5-97.5 and 95-100
- eps (optional, positive integer,default= 4)  distance to the nearest neighbor in x-y cordinates
- min_samples (optional ,positive integer, default=10)  min number of peptide lawns required to be considered a cluster
- save_plot = save_plot (optional, boolean, default=true) set to true to export plots of the clusters to output-charts dir.  No chart is made if a sample does not have any clusters.

## exclude_clustered_data
Excludes clusters as these are likely instrumentation errors
- df_out_name (required, string) DataFrame output name to be accessed by other transformations
- df_in_name (required, string) DataFrame input name
- descriptor_columns (optional, list [], default uses all descriptor columns)
- unstack (optional, boolean, default=true) unstacks/pivots the data prior to output.
- filter_clusters (optional, boolean, default=true) removes data that are in the clusters
- filter_expanded (optional, boolean, default=true) expands the cluster to peptides lawns within the smallest convex polymer (convex hull). THis is because if there it is likely all lawns within the area are corrupted, not just the ones directly flagging
- min_original_cluster_size (optional, integer, default=10) (allows you to change the cluster size, but it cannot be smaller than the find clusters)
- min_cluster_ratio  (optional, float betweeen 0 and 1, default=0)  The number of expanded vs not expanded. that meets filtering criteria. Set to 0 to include all expanded in the filter
- sample_name_col (required, string) the sample name such as "SAMPLE_NAME"
- intensity_col (optional, string, default='INTENSITY') the column of intensity that was used in the analysis.

## shift_baseline
Shifts the baseline of each (by subtracting the declared percentile)
- percentile (optional, float, default=25)
- transform_columns (optional, string) Which data column to transform)
- df_out_name (required, string) DataFrame output name to be accessed by other transformations
- df_in_name (required, string) DataFrame input name

## subtract_columns_class
Must match up with the metadata columns names
Each row must contain what to subtract
- subtract_column (required, string)  Name of the Subtract column (not the smaple name) header in the metadata 
- sample_name (required, string) header of column in the metadata where we get the column from.
- subtract_dict (optional, dict,  if not using a meta data table with subtract colums)
- df_out_name (required, string) DataFrame output name to be accessed by other transformations
- df_in_name (required, string) DataFrame input name

## median_group_by
- group_by_columns (required, list []), default='['PROBE_SEQUENCE', 'PEP_LEN'] ignores missing, but at least one header must be present
- df_out_name (optional, string) DataFrame output name to be accessed by other transformations
- df_in_name (optional, string) DataFrame input name

## rolling_median
- group_by_columns (required, list []) the columns to group the rolling median by
- sort_by_columns (required, list []) the columns to sort the rolling median by, order matters)
- rolling_window (optional, integer, default = 3) how many rows of data to use in calculating median
- df_out_name (required, string) DataFrame output name to be accessed by other transformations
- df_in_name (required, string) DataFrame input name
- data_stacked (optional, boolean, default=true) Set to false if input dataframe is not stacked 

## local_spatial_correction
Looks at the immediate surrounding values of the peptide lawns and normalizes to those values using a spline
Many times the signal is blurry / noisy /signal bleed  and expands to the adjacent lawns.  This normalization can take that into consideration and correct for it
For example if two peptide lawns surrounding the targe lawn is high, the target lawns value may be inflated due to this signal bleed
Uses statsmodels.api sm package, sm.nonparametric.lowess
- df_out_name (required, string) DataFrame output name to be accessed by other transformations
- df_in_name (required, string) DataFrame input name
- intensity_col (optional, string, default='INTENSITY') the column of intensity that was used in the analysis.
- empty_slot_value (optional, integer, default=-3) value to designate to an empty peptide lawn (or if the adjacent lawn is off the substrate)
- frac (optional, float 0 to 1, default = 0.3) from sm.nonparametric.lowess
- it = (optional, integer, default = 3) from sm.nonparametric.lowess
- delta = (optional, float 0 to 1, default = 0.01) from sm.nonparametric.lowess
- descriptor_columns(optional, list [], default all descriptor_columns)
- save_plot (optional, boolean, default=true) set to true to export plots of the clusters to OUTPUT_CHARTS_DIR. 
- save_table (optional, boolean, default=true) set to true to export plots of the clusters to OUTPUT_CHARTS_DIR
- OUTPUT_CHARTS_DIR (required, string) file path on where the clustering charts end up.

## large_area_spatial_correction
This looks at the over all gradiant (by the window size) of the sample to see if there is any bias to the signal across the substrate
Looks at the median over a large area, and then normalizes to that value.
- df_out_name (optional, string) DataFrame output name to be accessed by other transformations
- df_in_name (optional, string) DataFrame input name
- descriptor_columns(optional, list [], default all descriptor_columns)
- window_size (optional, integer, default=75) the rectangle square (in x-y cordinates units) used to find the median on a rolling bassis
- save_plot (optional, boolean, default=true) set to true to export plots of the clusters to output-charts dir. 
- OUTPUT_CHARTS_DIR (required, string) file path on where the clustering charts end up.

## merge_corresponding_files
This primarily used for merging corresponding sequence files created by NimbleGen
- corr_primary_name (required, string) this is the df name. You must have it already opened with open_files
- corr_secondary_name (required, string)  this is the df name. You must have it already opened with open_files
- SEQ_ID (required, string, default = 'SEQ_ID') This is the SEQ_ID column
- REDUNDANT (required, string), default = 'REDUNDANT')  This is the Redundant column
- df_out_name (required, string, default ='corr_merged') This is the output df name that can be accessed later in the transforms


## Example Pipeline file
```java
[
	{
		"name" : "open_data_meta_files",
		"order" : 0.1,
		"transformation_func":"open_data_meta_files",
		"transformation_args" : {
			"data_filepaths": "/scratch/Raw_aggregate_data_igg.txt",
			"data_sep":"\t",
			"meta_filepaths":"/scratch/meta_igg.csv",
			"meta_sep":","
			}
	},
	{
		"name" : "log_transform",
		"order" : 1,
		"transformation_func":"log_transform",
		"transformation_args" : {
			"base" : 2,
			"df_in_name" : "df",
			"df_out_name" : "df"
		}
	},
	{
		"name" : "Find Clusters and Merge with DF",
		"order" : 2.0,
		"transformation_func":"find_clusters",
		"transformation_args" : {
			"df_in_name":"df",
			"df_cluster_name":"expanded_cluster",
			"df_out_name":"df_clustered",
			"OUTPUT_CHARTS_DIR":"/scratch/out_charts",
			"merge_to_input_df":true,
			"percentile_slices":20,
			"eps":3,
			"min_samples":10,
			"save_plot":true
		}
	},

	{
		"name" : "Exclude clusters",
		"order" : 2.2,
		"transformation_func":"exclude_clustered_data",
		"transformation_args" : {
			"df_in_name":"df_clustered",			
			"df_out_name":"df",
			"unstack":true,
			"filter_clusters":true,
			"filter_expanded":true,
			"min_original_cluster_size":10,
			"min_cluster_ratio":0
		}
	},

	{
		"name" : "local_spatial_correction",
		"order" : 3.0,
		"transformation_func":"local_spatial_correction",
		"transformation_args" : {
			"df_in_name":"df",			
			"df_out_name":"df",
			"empty_slot_value":2,
			"save_plot":true,
			"save_table":true,
			"OUTPUT_CHARTS_DIR":"/scratch/out_charts"
		}
	},
	{
		"name" : "large_area_spatial_correction",
		"order" : 4.0,
		"skip" : false,
		"transformation_func":"large_area_spatial_correction",
		"transformation_args" : {
			"df_in_name":"df",			
			"df_out_name":"df",
			"window_size":75,
			"save_plot":true,
			"OUTPUT_CHARTS_DIR":"/scratch/out_charts"
		}
	},
	

	
	{
		"name" : "Take Median of Replicates",
		"order" : 5.0,
		"transformation_func":"median_group_by",
		"transformation_args" : {
			"df_in_name":"df",			
			"df_out_name":"df",
			"group_by_columns" : ["PROBE_SEQUENCE","PEP_LEN","EXCLUDE"]
		}
	},
	{
		"name" : "Shift to the 25 percentile",
		"order" : 6.0,
		"transformation_func":"shift_baseline",
		"transformation_args" : {
			"df_in_name":"df",			
			"df_out_name":"df",
			"percentile" : 25
		}
	},
	{
		"name" : "Stack Data",
		"order" : 7.0,
		"transformation_func":"melt_class",
		"transformation_args" : {
			"df_in_name":"df",			
			"df_out_name":"stacked",
			"value_name" : "INTENSITY",
			"var_name":null
		}
	},
	{
		"name" : "Merge Stack Data with Meta Data",
		"order" : 8.0,
		"transformation_func":"merge_data_frames",
		"transformation_args" : {
			"df_name_left":"meta",			
			"df_name_right":"stacked",
			"df_out" : "stacked",
			"how" : "inner"
		}
	},
	
	{
		"name" : "open_files corr_wuhan_only",
		"order" : 9.0,
		"transformation_func":"open_files",
		"transformation_args" : {
			"filepaths" : "/scratch/wuhan_seq_only.tsv.gz",
			"df_out_name" : "corr_wuhan_only",
			"required_descriptor_columns" : ["SEQ_ID","PROBE_SEQUENCE", "POSITION"],
			"keep_columns":["SEQ_ID", "SEQ_NAME", "PROTEIN", "POSITION", "PROBE_SEQUENCE"],
			"rename_dictionary":{"PROBE_SEQUENCE":"PROBE_SEQUENCE", "SEQ_ID":"SEQ_ID", "POSITION":"POSITION", "PROTEIN":"PROTEIN", "SEQ_NAME":"SEQ_NAME"},
			"sep":"\t"
		}
	},

	{
		"name" : "Merge Stack Meta data and corr_wuhan_only",
		"order" : 9.1,
		"transformation_func":"merge_data_frames",
		"transformation_args" : {
			"df_name_left":"corr_wuhan_only",			
			"df_name_right":"stacked",
			"df_out" : "corr_wuhan_only",
			"how" : "inner"
		}
	},
	{
		"name" : "save corr_wuhan_only_to_tsv",
		"order" : 9.2,
		"transformation_func":"save_to_csv",
		"transformation_args" : {
			"sep" : "\t",
			"df_in_name" : "corr_wuhan_only",
			"filepath" : "/scratch/out/stacked_wuhan_only.tsv"
		}
	},
	
	{
		"name" : "open_files corr all_seq_except_wi",
		"order" : 10.0,
		"skip" : true,
		"transformation_func":"open_files",
		"transformation_args" : {
			"filepaths" : "/scratch/all_seq_except_wi.tsv.gz",
			"df_out_name" : "corr_all_seq_except_wi",
			"required_descriptor_columns" : ["SEQ_ID","PROBE_SEQUENCE", "POSITION"],
			"keep_columns":["SEQ_ID", "SEQ_NAME", "PROTEIN", "POSITION", "PROBE_SEQUENCE"],
			"rename_dictionary":{"PROBE_SEQUENCE":"PROBE_SEQUENCE", "SEQ_ID":"SEQ_ID", "POSITION":"POSITION", "PROTEIN":"PROTEIN", "SEQ_NAME":"SEQ_NAME"},
			"sep":"\t"
		}
	},

	{
		"name" : "Merge Stack Meta data and stacked_all_seq_except_wi",
		"order" : 10.1,
		"skip" : true,
		"transformation_func":"merge_data_frames",
		"transformation_args" : {
			"df_name_left":"corr_all_seq_except_wi",			
			"df_name_right":"stacked",
			"df_out" : "corr_all_seq_except_wi",
			"how" : "inner"
		}
	},
	{
		"name" : "save corr_stacked_all_seq_except_wi",
		"order" : 10.2,
		"skip" : true,
		"transformation_func":"save_to_csv",
		"transformation_args" : {
			"sep" : "\t",
			"df_in_name" : "corr_all_seq_except_wi",
			"filepath" : "/scratch/out/stacked_all_seq_except_wi.tsv"
		}
	},
	{
		"name" : "save log_transform_to_tsv",
		"order" : 1.1,
		"transformation_func":"save_to_csv",
		"transformation_args" : {
			"sep" : "\t",
			"df_in_name" : "df",
			"filepath" : "/scratch/out/df_log_transform.tsv"
		}
	},
	{
		"name" : "Save df_clustered to .tsv",
		"order" : 2.1,
		"transformation_func":"save_to_csv",
		"transformation_args" : {
			"sep" : "\t",
			"df_in_name" : "df_clustered",
			"filepath" : "/scratch/out/df_clustered.tsv"
		}
	},
	
	{
		"name" : "Save df_excluded_clusters to .tsv",
		"order" : 2.3,
		"transformation_func":"save_to_csv",
		"transformation_args" : {
			"sep" : "\t",
			"df_in_name" : "df",
			"filepath" : "/scratch/out/df_clustered.tsv"
		}
	},
	
	
	{
		"name" : "Save median to .tsv",
		"order" : 5.1,
		"transformation_func":"save_to_csv",
		"transformation_args" : {
			"sep" : "\t",
			"df_in_name" : "df",
			"filepath" : "/scratch/out/df_median.tsv"
		}
	},
	{
		"name" : "Save shifted baseline to .tsv",
		"order" : 6.1,
		"transformation_func":"save_to_csv",
		"transformation_args" : {
			"sep" : "\t",
			"df_in_name" : "df",
			"filepath" : "/scratch/out/df_baseline_shifted.tsv"
		}
	},
	{
		"name" : "Save stacked to .tsv",
		"order" : 8.1,
		"transformation_func":"save_to_csv",
		"transformation_args" : {
			"sep" : "\t",
			"df_in_name" : "stacked",
			"filepath" : "/scratch/out/df_stacked.tsv"
		}
	}
]
```
# References
AK, et al. (2020) “High-Throughput Identification of MHC Class I Binding Peptides Using an Ultradense Peptide Array.” J Immunol. 204(6): 1689-96. doi: 10.4049/jimmunol.1900889

Heffron AS, et al. (2018) "Antibody responses to Zika virus proteins in pregnant and non-pregnant macaques." PLoS NTD. 12(11): e0006903. doi: 10.1371/journal.pntd.0006903

Bailey A, et al. (2017) "Pegivirus avoids immune recognition but does not attenuate acute-phase disease in a macaque model of HIV infection." PLoS Pathogens. 13(10): e1006692. doi: 10.1371/journal.ppat.1006692

https://www.nimbletherapeutics.com/technology
