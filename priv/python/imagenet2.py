from functools import singledispatch
import json
import os

import keras
from keras.applications.resnet50 import ResNet50, preprocess_input
from keras.layers import Dense, Activation, Flatten, Dropout
from keras.models import Sequential, Model
from keras.preprocessing.image import ImageDataGenerator
from keras.optimizers import SGD, Adam
from keras.callbacks import ModelCheckpoint
import matplotlib.pyplot as plt
import numpy
from sklearn.metrics import confusion_matrix, classification_report

@singledispatch
def to_serializable(val):
    """Used by default."""
    return str(val)

@to_serializable.register(numpy.float32)
def ts_float32(val):
    """Used if *val* is an instance of numpy.float32."""
    return numpy.float64(val)

def train(logging_cb, project_id, epochs):
    VER = 'v2';
    HEIGHT = 256
    WIDTH = 256
    BATCH_SIZE = 4
    EPOCHS = epochs
    FC_LAYERS = [WIDTH // 2, HEIGHT // 2]
    NUM_TRAIN = 500

    BASE_DIR = os.path.dirname(__file__)
    TRAIN_DIR = os.path.join(BASE_DIR, "__hairyimage_cache__/train")
    TEST_DIR = os.path.join(BASE_DIR, "__hairyimage_cache__/test")
    opts = f"{VER},{WIDTH},{HEIGHT},{BATCH_SIZE},{EPOCHS},{'.'.join([str(x) for x in FC_LAYERS])},{NUM_TRAIN}"
    MODEL_FNAME = os.path.join(BASE_DIR, f"imagenet.model/{project_id}-{opts}.h5")
    PLOT_FNAME = os.path.join(BASE_DIR, f"imagenet.model/{project_id}-{opts}-plot.png")
    STATS_FNAME = os.path.join(BASE_DIR, f"imagenet.model/{project_id}-{opts}-stats.json")

    def _send(msg):
        print('send',msg)
        logging_cb(msg)

    class LoggingCallback(keras.callbacks.Callback):
        def on_train_batch_end(self, batch, logs=None):
            _send(('train_batch',logs))
        def on_test_batch_end(self, batch, logs=None):
            _send(('test_batch',logs))
        def on_epoch_end(self, epoch, logs=None):
            _send(('epoch',logs))

    def build_model(base_model, dropout, fc_layers, num_classes):
        for layer in base_model.layers:
            layer.trainable = False

        x = base_model.output
        x = Flatten()(x)
        for fc in fc_layers:
            # New FC layer, random init
            x = Dense(fc, activation='relu')(x) 
            x = Dropout(dropout)(x)

        # New softmax layer
        predictions = Dense(num_classes, activation='softmax')(x) 
        model = Model(inputs=base_model.input, outputs=predictions)
        return model

    def plot_training(history):
        acc = history.history['accuracy']
        loss = history.history['loss']
        epochs = range(len(acc))

        plt.plot(epochs, acc, 'r.')
        plt.title('Training and validation accuracy')

        plt.figure()
        plt.plot(epochs, loss, 'r.')
        plt.title(opts)
        plt.show()
        plt.savefig(PLOT_FNAME)

    _send(('start', MODEL_FNAME))

    datagen = ImageDataGenerator(preprocessing_function=preprocess_input, 
        horizontal_flip=True, vertical_flip=True, zoom_range=2)

    train_generator = datagen.flow_from_directory(TRAIN_DIR, target_size=(HEIGHT, WIDTH), batch_size=BATCH_SIZE)
    test_generator = datagen.flow_from_directory(TEST_DIR, target_size=(HEIGHT, WIDTH), batch_size=BATCH_SIZE)

    classes = train_generator.class_indices.keys()
    _send(('classes',classes))

    base_model = ResNet50(weights='imagenet', 
        include_top=False, 
        input_shape=(HEIGHT, WIDTH, 3))

    dropout = 0.5

    model = build_model(base_model, 
        dropout=dropout, 
        fc_layers=FC_LAYERS, 
        num_classes=len(classes))

    # XXX should send model representation back to Elixir here to display
    adam = Adam(lr=0.00001)
    model.compile(adam, loss='categorical_crossentropy', metrics=['accuracy'])

    cb_save_model = ModelCheckpoint(MODEL_FNAME, monitor=["acc"], verbose=1, mode='max')
    cb_send_log = LoggingCallback()
    callbacks_list = [cb_save_model, cb_send_log]

    history = model.fit_generator(train_generator, epochs=EPOCHS, workers=4, 
        steps_per_epoch=NUM_TRAIN // BATCH_SIZE, 
        shuffle=True, callbacks=callbacks_list, validation_data=test_generator)
    _send(('done', MODEL_FNAME))

    Y_pred = model.predict_generator(test_generator, test_generator.samples // BATCH_SIZE+1)
    # print('predicted',Y_pred)
    # print('truth',test_generator.classes)
    y_pred = numpy.argmax(Y_pred, axis=1)
    cm = confusion_matrix(test_generator.classes, y_pred)
    _send(('confusion_matrix', cm))
    cr = classification_report(test_generator.classes, y_pred, target_names=classes)
    _send(('classification_report', cr))
    stats = {
        "config": opts,
        "confusion_matrix": cm,
        "classification_report": cr
    };
    open(STATS_FNAME, 'w').write(json.dumps(stats, default=to_serializable))
    plot_training(history)



