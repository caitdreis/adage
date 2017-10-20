 #!/bin/bash
 
 ############
    ##Path Two##
    ############
    #If you want to reproduce our analysis, we only included datasets that are available before 02/22/2014 in the compendium. You can start from here using the already processed expression compendium provided as Data_collection_processing/Pa_compendium_02.22.2014.pcl and the processed test sets Data_collection_processing/Genome-hybs-gene.pcl and Data_collection_processing/Anr-gene.pcl.
    #Note that test set processing also depends on the compendium. If you process the test set with an up-to-date compendium, then the expression values in the resulting test set might be slightly different.


#If you are using an up-to-date compendium, replace Pa_compendium_02.22.2014.pcl with the up-to-date compendium in the following analyses.
#Note that the node order will change if you train a new DA on an updated compendium.

#To prepare for DA training, each gene expression vector is linearly normalized to the range between 0 and 1. 
python Data_collection_processing/zero_one_normalization.py Data_collection_processing/Pa_compendium_02.22.2014.pcl Train_test_DAs/train_set_normalized.pcl None

#Test set is normalzied using the same minimums and ranges used above.
python Data_collection_processing/zero_one_normalization.py Data_collection_processing/Genome-hybs-gene.pcl Train_test_DAs/Genome-hybs_normalized.pcl Data_collection_processing/Pa_compendium_02.22.2014.pcl
python Data_collection_processing/zero_one_normalization.py Data_collection_processing/Anr-gene.pcl Train_test_DAs/Anr_normalized.pcl Data_collection_processing/Pa_compendium_02.22.2014.pcl
python Data_collection_processing/zero_one_normalization.py Data_collection_processing/Anr_RNAseq_PAO1_gene.pcl Train_test_DAs/Anr_RNAseq_PAO1_gene_normalized.pcl Data_collection_processing/Pa_compendium_02.22.2014.pcl
python Data_collection_processing/zero_one_normalization.py Data_collection_processing/Anr_RNAseq_J215_gene.pcl Train_test_DAs/Anr_RNAseq_J215_gene_normalized.pcl Data_collection_processing/Pa_compendium_02.22.2014.pcl

#######################################
#Section two: training and testing DAs#
#######################################

#Running the following codes requires installing python packages Theano and docopt
#Instruction for Theano: http://deeplearning.net/software/theano/install.html
#Instruction for docopt: https://pypi.python.org/pypi/docopt

#Train a denoising autoencoder using network size 50, batch size 10, epoch size 500, corruption level 0.1, learning rate 0.01
python Train_test_DAs/SdA_train.py Train_test_DAs/train_set_normalized.pcl 0 50 10 500 0.1 0.01 --seed1 123 --seed2 123

#Test the test set on already trained DA. 
python Train_test_DAs/SdA_test.py Train_test_DAs/Genome-hybs_normalized.pcl 0 Train_test_DAs/train_set_normalized_50_batch10_epoch500_corrupt0.1_lr0.01_seed1_123_seed2_123_network_SdA.txt 50
python Train_test_DAs/SdA_test.py Train_test_DAs/Anr_normalized.pcl 0 Train_test_DAs/train_set_normalized_50_batch10_epoch500_corrupt0.1_lr0.01_seed1_123_seed2_123_network_SdA.txt 50
python Train_test_DAs/SdA_test.py Train_test_DAs/Anr_RNAseq_PAO1_gene_normalized.pcl 0 Train_test_DAs/train_set_normalized_50_batch10_epoch500_corrupt0.1_lr0.01_seed1_123_seed2_123_network_SdA.txt 50
python Train_test_DAs/SdA_test.py Train_test_DAs/Anr_RNAseq_J215_gene_normalized.pcl 0 Train_test_DAs/train_set_normalized_50_batch10_epoch500_corrupt0.1_lr0.01_seed1_123_seed2_123_network_SdA.txt 50

#Plot the distribution of activity values for each hidden node and the distribution of weight vector for each node
mkdir -p Train_test_DAs/activity_plot
mkdir -p Train_test_DAs/weight_plot
mkdir -p Train_test_DAs/raw_activity_plot
R --no-save < Train_test_DAs/plot_distribution.R

#Get high-weight genes for each nodes
mkdir -p Train_test_DAs/high_weight_gene/2std
python Train_test_DAs/high_weight_gene.py 2 Train_test_DAs/train_set_normalized.pcl Train_test_DAs/train_set_normalized_50_batch10_epoch500_corrupt0.1_lr0.01_seed1_123_seed2_123_network_SdA.txt Train_test_DAs/high_weight_gene/2std

#Change gene symbol to gene name
mkdir -p Train_test_DAs/high_weight_gene/2std_symbol
python Train_test_DAs/symbol2name_HW_gene.py Train_test_DAs/high_weight_gene/2std Train_test_DAs/high_weight_gene/2std_symbol

#Combine high-weight genes for each node into one file
for x in Train_test_DAs/high_weight_gene/2std_symbol/Node*; do basename -s .txt $x > $x.titled; cat $x >>$x.titled;cut -f 1 $x.titled > $x.cut; done
paste Train_test_DAs/high_weight_gene/2std_symbol/*.cut > Train_test_DAs/high_weight_gene/2std_combined.txt
rm Train_test_DAs/high_weight_gene/2std_symbol/*.cut
rm Train_test_DAs/high_weight_gene/2std_symbol/*.titled

#Plot the relationship between the number of nodes a gene contributing high-weight to and the expression variance of the gene
R --no-save < Train_test_DAs/HWgene_variance.R


##################################
#Section three: positive controls#
##################################

#Download operon gold standard from DOOR database and store them in a file
python Genome_organization/download_operon.py Genome_organization/operon_all.txt 0
#only include operons with more than 3 genes
python Genome_organization/download_operon.py Genome_organization/operon_3.txt 3 
#In case the DOOR online database is down, the operon files are also provided in the repository.
