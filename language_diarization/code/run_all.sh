#  
#


#  This script runs the baseline system for language diarization for 
#  DISPLACE 2024 challenge 
# 
#  This bash script is a wrapper for different  python3 scripts
#  It uses libraries 
#      - pyannote.audio 0.01, 
#      - openai-whisper 
#      - ffmpeg 
#      -fastcluster	
#------------------------------------------------
#    Configuration
#------------------------------------------------

stage=0    
      # stage 0 - data preparation
      # Stage 1 - feature extraction and vad 
      # Stage 2 - diarization 

PYTHON=python3 

SEG_DUR=10    # maximum segment duration in sec
SEG_SHIFT=0.4 # shift to the next segment in sec
SEG_OVRLAP=`echo "$SEG_DUR - $SEG_SHIFT" | bc -l` 



#------------------------------------------------
#    Dev and Eval folders 
#------------------------------------------------

DISPLACE_DEVDATA='../data/dev'
DISPLACE_EVALDATA='../data/eval'
OUTPUT_DIR='../output'


#------------------------------------------------
#    VAD Preparation
#------------------------------------------------

VAD_SUBDIR='dev/'
SEG_SUBDIR='devseg/'
KAL_SUBDIR='kal_devseg/'

$PYTHON pyannote_vad.py $DISPLACE_DEVDATA  $OUTPUT_DIR $VAD_SUBDIR $SEG_SUBDIR

path_segments="$OUTPUT_DIR/$SEG_SUBDIR"
path_new_kaldi_segs="$OUTPUT_DIR/$KAL_SUBDIR"
mkdir -p $path_new_kaldi_segs
for path in $(ls $path_segments)
do
    g=${path_segments}/${path}
    $PYTHON seg2kaldi.py $g ${path_new_kaldi_segs}${path}.txt
done



#-------------------------------------------------
#    Subsegment Creation
#-------------------------------------------------

SUBSEG_SUBDIR='dev_subseg/'
path_subsegs="$OUTPUT_DIR/$SUBSEG_SUBDIR"
mkdir -p $path_subsegs


echo Creating subsegments..
$PYTHON create_subseg.py --input_folder $path_new_kaldi_segs --out_subsegments_folder $path_subsegs --max-segment-duration $SEG_DUR --overlap-duration $SEG_OVRLAP --max-remaining-duration $SEG_DUR --constant-duration False

#-------------------------------------------------
#    Feature Extraction
#-------------------------------------------------

#
FEAT_SUBDIR='dev_feat/'
mkdir -p $OUTPUT_DIR/$FEAT_SUBDIR

echo Extracting features... 
$PYTHON feat_extr.py --aud_path $DISPLACE_DEVDATA  --out_dir $OUTPUT_DIR/$FEAT_SUBDIR --seg_dir  $OUTPUT_DIR/$SUBSEG_SUBDIR



#-------------------------------------------------
#    Clustering (AHC)
#-------------------------------------------------

FEAT_SEG_TSV='dev_whisp_feat.tsv'
RTTM_OUT_DIR='dev_rttm_outdir'
CLUSTER_ALGO='AHC'
mkdir -p $OUTPUT_DIR/$RTTM_OUT_DIR

ls -1 $OUTPUT_DIR/$SUBSEG_SUBDIR/*.txt  | sort > $OUTPUT_DIR/temp_segs
ls -1 $OUTPUT_DIR/$FEAT_SUBDIR/*.npy | sort > $OUTPUT_DIR/temp_posteriors
paste $OUTPUT_DIR/temp_posteriors $OUTPUT_DIR/temp_segs > $OUTPUT_DIR/$FEAT_SEG_TSV
$PYTHON clustering.py $OUTPUT_DIR/$FEAT_SEG_TSV $OUTPUT_DIR/$RTTM_OUT_DIR $CLUSTER_ALGO
	

#-------------------------------------------------
#    Scoring
#-------------------------------------------------

ref_RTTM=$OUTPUT_DIR/dscore/dev_original.rttm
sys_RTTM=$OUTPUT_DIR/dscore/sys_dev_whisper.rttm

cat $OUTPUT_DIR/$RTTM_OUT_DIR/*.rttm  > $sys_RTTM
$PYTHON score.py -r $ref_RTTM -s $sys_RTTM 
