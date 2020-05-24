import erlport
import json
import os
import pickle
import random
import re
import spacy
import sys

ITERS = 10
BASE_DIR = os.path.dirname(__file__)

def make_tdata(s):
    orig = s
    label = None
    m = re.match(r"^(%LABEL__(.+?)%)", s)
    if m:
        label = m[2]
        if label not in LABELS:
            print('bad label', label, LABELS)
            raise KeyError
        s = s.replace(m[1], '')
    s2 = s
    out = []
    while 1:
        m = re.search(r"(%(.+?)__(.+?)%)", s2)
        # print(m)
        if m:
            # print(m[0])
            # print(m[1])
            s2 = s2.replace(m[1], m[3])
            idx = s2.index(m[3])
            out.append((idx, idx+len(m[3]), m[2]))
        else:
            if label:
                return (orig, s2, {"entities": out, "cats": {label: 1}}) #, "_tagged_text": orig})
            else:
                return (orig, s2, {"entities": out}) # "_tagged_text": orig})

def dec(txt):
    return txt.decode('UTF-8')

def train(epochs, project_id, clientpid, train_data_raw):
    project_id = str(project_id)
    model_dir = os.path.join(BASE_DIR, "spacy.model", project_id)
    try:
        os.makedirs(model_dir)
    except:
        pass
    train_data_raw = list(train_data_raw)
    train_data = []
    for item in train_data_raw:
        print('processing',item)
        ents = []
        for ent in item[1][0]:
            print(ent)
            ents.append((ent[0], ent[1], dec(ent[2])))
        cat = dec(item[1][1])
        r = (dec(item[0]), (ents, cat))
        train_data.append(r)
    print(f'training with {len(train_data)} records\nfirst: {train_data[0]}\nlast: {train_data[-1]}')
    nlp = spacy.blank("en")
    if "ner" not in nlp.pipe_names:
        ner = nlp.create_pipe("ner")
        nlp.add_pipe(ner, last=True)
        # otherwise, get it so we can add labels
    else:
        ner = nlp.get_pipe("ner")

    if 'textcat' not in nlp.pipe_names:
        textcat = nlp.create_pipe("textcat")
        nlp.add_pipe(textcat, last=True) 
    else:
        textcat = nlp.get_pipe("textcat")

    for _, annotations in train_data:
        #print('annotations',annotations)
        textcat.add_label(annotations[1])
        for ent in annotations[0]:
            #print('adding label', ent[2])
            ner.add_label(str(ent[2]))

    optimizer = nlp.begin_training()
    for i in range(epochs):
        loss = {}
        random.shuffle(train_data)
        for text, annotations in train_data:
            text = str(text)
            ents = []
            for item in annotations[0]:
                ents.append([item[0], item[1], str(item[2])])
            ann = {"entities": ents, "cats": {str(annotations[1]): 1.0}}
            # print('final text', text)
            # print('final training data', [text, ann])
            nlp.update([text], [ann], sgd=optimizer, losses=loss)
        loss['epoch'] = i
        print('loss',loss)
        erlport.erlang.cast(clientpid, ('loss', json.dumps(loss)))
    nlp.to_disk(model_dir)
    return json.dumps(loss)

def predict(project_id, txt):
    def b(txt):
        return bytes(txt, 'utf-8')
    nlp2 = spacy.load(os.path.join(BASE_DIR, "trained.model", project_id))
    doc = nlp2(str(txt))
    print(doc.ents)
    print(dir(doc.ents))
    return {"text": txt, "classification": doc.cats, "entities": [[b(x.label_),b(x.text)] for x in doc.ents]}

print('hairytext.py started')

