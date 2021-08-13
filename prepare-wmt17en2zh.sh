#!/bin/bash
# Adapted from https://github.com/facebookresearch/MIXER/blob/master/prepareData.sh

export LC_ALL=en_US.UTF-8

echo 'Cloning Moses github repository (for tokenization scripts)...'
git clone https://github.com/moses-smt/mosesdecoder.git

echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
git clone https://github.com/rsennrich/subword-nmt.git

SCRIPTS=mosesdecoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
NORM_PUNC=$SCRIPTS/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$SCRIPTS/tokenizer/remove-non-printing-char.perl
BPEROOT=subword-nmt/subword_nmt
BPE_TOKENS=32000

PYTHON=/userhome/anaconda3/envs/pytorch1.2-release-py3.6/bin/python

if [ ! -d "$SCRIPTS" ]; then
    echo "Please set SCRIPTS variable correctly to point to Moses scripts."
    exit
fi

src=en
tgt=zh
lang=en-zh
prep=wmt17_en_zh
tmp=$prep/tmp

trainset=train
devset=valid
testset=test

echo "pre-processing train/valid/test data..."
$PYTHON deduplicate_lines.py --src $tmp/$trainset.raw.$src --tgt $tmp/$trainset.raw.$tgt --workers 32

cat $tmp/$trainset.raw.$src.dup | \
    perl $REM_NON_PRINT_CHAR | \
    perl $TOKENIZER -threads 32 -a -l $src > $tmp/$trainset.pr.$src

cat $tmp/$trainset.raw.$tgt.dup | \
    perl $REM_NON_PRINT_CHAR | \
    $PYTHON -m jieba -d > $tmp/$trainset.pr.$tgt

for dataset in $devset $testset; do
    cat $tmp/$dataset.raw.$src | \
        perl $TOKENIZER -threads 32 -a -l $src > $tmp/$dataset.tok.$src

    cat $tmp/$dataset.raw.$tgt | \
        ${PYTHON} -m jieba -d > $tmp/$dataset.tok.$tgt
done

$PYTHON remove_blanks.py --src $tmp/${trainset}.pr.$src --tgt $tmp/${trainset}.pr.$tgt --workers 32
$PYTHON is_chinese.py --src $tmp/${trainset}.pr.$src.rmb --tgt $tmp/${trainset}.pr.$tgt.rmb --workers 32

mv $tmp/${trainset}.pr.$src.rmb.ic $tmp/${trainset}.cl.$src
mv $tmp/${trainset}.pr.$tgt.rmb.ic $tmp/${trainset}.cl.$tgt

perl $CLEAN $tmp/$trainset.cl ${src} ${tgt} $tmp/$trainset.tok 1 80

BPE_CODE=$prep/code

echo "learn_bpe.py on ${trainset}..."
python $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $tmp/$trainset.tok.$src > $BPE_CODE.$src
python $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $tmp/$trainset.tok.$tgt > $BPE_CODE.$tgt

for f in ${trainset} ${devset} ${testset}; do
    echo "apply_bpe.py to ${f}..."
    python $BPEROOT/apply_bpe.py -c $BPE_CODE.$src < $tmp/$f.tok.$src > $prep/$f.$src
    python $BPEROOT/apply_bpe.py -c $BPE_CODE.$tgt < $tmp/$f.tok.$tgt > $prep/$f.$tgt
done
