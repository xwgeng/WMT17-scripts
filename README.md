# Scripts for WMT17 English-Chinese translation task
This repository contains preprocessing scripts used for [WMT17 English-Chinese translation task](http://www.statmt.org/wmt17/) at the 2017 Workshops on Statistical Machine Translation.
## Dependencies
* [Moses](https://github.com/moses-smt/mosesdecoder)
* [Subword-nmt](https://github.com/rsennrich/subword-nmt)
* [Jieba tokenier](https://github.com/fxsjy/jieba)

## Preprocessing
We build the preprocessing scripts used for WMT17 Chinese-English translation task mostly following [Hassan et al. (2018)](https://arxiv.org/abs/1803.05567) resulting 20M sentence pairs but with some minor changes. Particularly, We filter the bilingual corpus according to the following criteria:
* Both the source and target sentence should contain at most 80 words.
* Sentence pairs with blank lines are removed. (`remove_blanks.py`)
* Chinese sentences without any Chinese characters are removed. (`is_chinese.py`)
* Duplicated sentence pairs are removed. (`deduplicate_lines.py`)

## Training
Using preprocessed dataset, we train transformer models in both base and big configurations([Vaswani et al., 2017](https://papers.nips.cc/paper/7181-attention-is-all-you-need.pdf)) based on [fairseq](https://github.com/pytorch/fairseq) toolkit with 8 Tesla V100 GPUs. The training scripts is:
```bash
python train.py \
    data-bin/wmt17.en-zh \
    --source-lang en --target-lang zh \
    --arch transformer_wmt_en_de \
    --save-dir model_dir \
    --ddp-backend=no_c10d \
    --criterion label_smoothed_cross_entropy \
    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
    --lr 0.0005 --lr-scheduler inverse_sqrt \
    --min-lr 1e-09 --warmup-updates 4000 \
    --warmup-init-lr 1e-07 --label-smoothing 0.1 \
    --dropout 0.25 --weight-decay 0.0 \
    --max-tokens 16000 \
    --log-format 'simple' --log-interval 100 \
    --fixed-validation-seed 7 \ 
    --save-interval-updates 10000 \
    --max-update 300000 \
    --update-freq 1 \ 
    --fp16 \
    --save-interval 1
```

## Evaluation
we utilizes newsdev2017 and newstest2017 as development and test sets respectively. we apply beam search with a beam width of 5 and tune length penalty of `[0.0, 0.2, · · · , 2.0]` in development set. [SacreBLEU](https://github.com/mjpost/sacrebleu/)([Post, 2018](https://www.aclweb.org/anthology/W18-6319.pdf)) is measured to evaluate the translation performance on WMT17 Chinese->English dataset.

|Model|Transformer-Base|Transformer-Big|
|:-:|:-:|:-:|
|BLEU|35.37|36.73|


