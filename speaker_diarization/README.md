<div align="left"><img src="../displace_img.png" width="550"/></div>
 

# Updates
[18/01/2024]: We have released the code to compute the Baseline for speaker diarization. 

The results are computed on the development set. 

# Baseline for speaker diarization 
The implementation of the speaker diarization baseline is largely similar to the  [DISPLACE 2023](https://github.com/displace2023/DISPLACE_Baselines). 
This baseline has been described in the DISPLACE 2023 challenge paper :
- Baghel, Shikha et al., “The DISPLACE Challenge 2023 - DIarization of SPeaker and LAnguage in
Conversational Environments,” in Proc. INTERSPEECH, 2023. ([paper](https://www.isca-speech.org/archive/pdfs/interspeech_2023/baghel23_interspeech.pdf))

The steps involve speech activity detection, front-end feature extraction, x-vector extraction, and PLDA scoring followed by Spectral Clustering (SC). The resegmentation is applied to refine speaker assignment using [VB-HMM](https://www.fit.vutbr.cz/research/groups/speech/publi/2018/diez_odyssey2018_63.pdf). 

The major changes in the DISPLACE 2024 baseline are:
1. Speech activity detection using [Pyannote SAD model](https://github.com/pyannote/pyannote-audio)
2. Overlap handling using [Pyannote overlap detector](https://github.com/pyannote/pyannote-audio) and VB-HMM together in the final stage.


# Prerequisites

The following packages are required to run the baseline.

- [Python](https://www.python.org/) >= 3.7
- [Kaldi](https://github.com/kaldi-asr/kaldi)
- [dscore](https://github.com/nryant/dscore)
- [pyannote.audio 0.0.1](https://github.com/pyannote/pyannote-audio)
    1. Accept [pyannote/segmentation-3.0](https://huggingface.co/pyannote/segmentation-3.0) user conditions.
    2. Create access token at hf.co/settings/tokens.
    3. Download pytorch_model.bin, config.yaml from [pyannote/segmentation-3.0](https://huggingface.co/pyannote/segmentation-3.0) to path vad_benchmarking/VAD_model/


The data should be arranged for the baseline experiments should be as follows:  
```
   
───<DEV/EVAL data dir>
    │
    └─── data
         |
         └─── rttm 
         |        |
         |        └───<<Session_ID>_speaker.rttm>
         │ 
         └─── wav
                 └───<<Session_ID>.wav>
                 
```
We request the participants to arrange the shared DEV and EVAL sets in the above format for running the baselines.
- The directory "rttm" should contain the rttm files corresponding to speaker splits.
- The directory "wav" should contain the corresponding wav files.
- The corresponding files in the directories are indicated by the <Session_ID>

  
# Running the baseline recipes
Change the path to
```bash
cd speaker_diarization/
```

## Dataset path
open ``run.sh`` in a text editor. The first section of this script defines paths to the Displace challenge DEV and EVAL releases and should look something like the following:

```bash
################################################################################
# Paths to DISPLACE releases
################################################################################

DISPLACE_DEV_DIR=/data1/shareef/Displace_DEV
DISPLACE_EVAL_DIR=/data1/shareef/Displace_EVAL
```
  
Change the variables ``DISPLACE_DEV_DIR`` and ``DISPLACE_DEV_DIR`` so that they point to the roots of the Displace DEV and EVAL releases on your filesystem. Save your changes, exit the editor, and run:

```bash
./run.sh
```
  
### RTTM files

Following the initial SC segmentation step, RTTM files for the DEV set are written to:

    exp/displace_diarization_nnet_1a_dev_fbank_spectral/per_file_rttm
  
Similarly, RTTM files for the EVAL set are written to:

    exp/displace_diarization_nnet_1a_eval_fbank_spectral/per_file_rttm

RTTM files will also be output after the VB-HMM resegmentation step, this time to:

- ``exp/displace_diarization_nnet_1a_vbhmm_dev_spectral_overlap/per_file_rttm``
- ``exp/displace_diarization_nnet_1a_vbhmm_dev_spectral_overlap/per_file_rttm``
  
### Scoring

The performance is evaluated using [Diaration error rate (DER)](https://github.com/nryant/dscore) as the primary metric.

DER = False Alarm speech + Missed Speech + Speaker Confusion error

- speaker error -- percentage of scored time for which the wrong speaker id is assigned within a speech region
- false alarm speech -- percentage of scored time for which a nonspeech region is incorrectly marked as containing speech
- missed speech -- percentage of scored time for which a speech region is incorrectly marked as not containing speech

DER on the DEV set for the output of the SC step will be printed to STDOUT
These scores are extracted from the original ``dscore`` logs, which are output to ``exp/displace_diarization_nnet_1a_dev_fbank_spectral/scoring``
Similarly, the scores for the VB-HMM are output to ``exp/displace_diarization_nnet_1a_vbhmm_dev_spectral_overlap/scoring`` 
  
# Expected results

Expected DER for the baseline system on the Displace challenge DEV set is presented in Table 1.


**Table 1: Baseline speaker diarization results for the DISPLACE development set using SC and SC followed by VB-HMM resegmentation with overlap handling.**

|  Method           | DER (Dev)   | DER (Eval) |
| ------------------| ----------- | -----------|
| SC                |   30.44     |   35.52    |
| VB-HMM + Overlap  |   29.16     |   34.76    |
  

  
<!-- ## Pretrained SAD model

We have placed a copy of the TDNN+stats SAD model used to produce these results on [Zenodo](https://zenodo.org/). To use this model, download and unarchive the [tarball](https://zenodo.org/record/4299009), then move it to ``speaker_diarization/exp``. -->

  


