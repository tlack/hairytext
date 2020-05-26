import erlport
from functools import singledispatch
import json
import os
import numpy
import pickle
import PIL
import random
import re
import sys

import imagenet2

TRAIN_TEST_MIX = 0.9

BASE_DIR = os.path.dirname(__file__)
CACHE_DIR = os.path.join(os.path.dirname(__file__), "__hairyimage_cache__")

@singledispatch
def to_serializable(val):
    """Used by default."""
    return str(val)

@to_serializable.register(numpy.float32)
def ts_float32(val):
    """Used if *val* is an instance of numpy.float32."""
    return numpy.float64(val)

def dec(txt):
    return txt.decode('UTF-8')

def cp(inf, outf):
    open(outf, 'wb').write(open(inf, 'rb').read())

def clear_training_batch_dir():
    for path, subdirs, files in os.walk(CACHE_DIR):
        for name in files:
            fn = os.path.join(path, name)
            print('removing', fn)
            os.remove(fn)

def generate_training_batch(batch_size, image_dir, train_data_raw):
    clear_training_batch_dir()
    files = []
    test_classes = []
    n_test = 0
    n_train = 0
    for record in train_data_raw:
        assert len(record) == 2
        class_ = dec(record[1])
        fname = dec(record[0])
        full_fname = os.path.join(image_dir, fname)

        if not os.path.exists(full_fname):
            err = ('error', 'noexist', full_fname) 
            print(err)
            # erlport.erlang.cast(clientpid, err)
            return err

        try:
            img = PIL.Image.open(full_fname)
        except:
            print("BAD IMAGE! ",fname)
            continue

        print(img.size)

        if class_ not in test_classes:
            test_classes.append(class_)
            tt = 'test'
            n_test += 1
        else:
            tt = 'train' if random.random() < TRAIN_TEST_MIX else 'test'
            if tt == 'train':
                n_train += 1
        files.append((full_fname, class_, tt))

    print('files', files)
    # erlport.erlang.cast(clientpid, ('files', files))

    r = []
    for f in files:
        newpath = os.path.join(CACHE_DIR, f[2], f[1])
        newfn = os.path.join(newpath, os.path.basename(f[0]))
        try:
            os.makedirs(newpath)
        except:
            pass
        cp(f[0], newfn)
        r.append(newfn)
    print('r', r)
    return r

def train(project_id, client_pid, image_dir, train_data_raw): 
    print('train_data_raw', image_dir, train_data_raw)
    generate_training_batch(2, dec(image_dir), train_data_raw)
    def log_cb(msg):
        print('log_cb',msg)
        erlport.erlang.cast(client_pid, ('log', json.dumps(msg, default=to_serializable)))
    imagenet2.train(log_cb, str(project_id), 25)

def predict(txt):
    return {"text": txt, "classification": doc.cats, "entities": [[b(x.label_),b(x.text)] for x in doc.ents]}

print('hairyimage.py started')

