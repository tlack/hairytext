# Hairy Text

![HairyText diagram](https://i.imgur.com/bKR3zlf.png)

Hairy Text is a tool for natural language processing. 

With Hairy Text, you can perform named entity recognition (NER) tasks using the
world-class [Spacy](https://spacy.io) library, and label data for training to
improve your model. All this from a normal looking and mobile-friendly web
application.

It is written in Elixir + Phoenix LiveView and Python, doesn't require a
database (totally self contained), and runs fine on a $5/mo server without a GPU.

# Screenshot

## List of examples for labeling
![HairyText Examples screenshot](https://i.imgur.com/2dvaxjx.png)

## Labeling interface in modal window
![HairyText Labeler screenshot](https://i.imgur.com/tWDeB6H.png)

## Testing unseen input (and adding to labeling queue)
![HairyText TEST screenshot](https://i.imgur.com/uXdzYx9.png)

# Features

* **Built with the awesome Spacy NLP framework** (so I probably didn't mess it up!)
* Easily label text fragments for machine learning / NLP experiments
* Interactive "test" console lets you quickly debug your model
* Refreshless but highly dynamic Phoenix Liveview web-based user interface (like React, without it)
* User logins with HTTP AUTH password check
* Export a .ZIP of your labeled examples and prediction history (both convenient .JSON files)
* REST JSON API for making predictions (to tie it into the rest of your project)
* API predictions stored in log and reviewable in app
* Label examples or images with a category/class
* Label text inside examples as entities - for instance "time reference" or "place name"
* Filter by entity tags or labels
* Train online via web interface and report live training progress (rough..)
* Support for multiple projects (some bugs)

# Future

* Make into embeddable component like LiveDashboard
* Support for "one at a time" editing that's more about a workflow of doing one labeling task after another
* Object detection (aka classify regions inside images)
* Assist in generating low-confidence predictions to more quickly improve model
* Each project should have its own DETS files
* APIs to: label examples new and old, bulk predict, view predictions log
* Learn from embeddings (BERT, I'm looking at you)
* uPlot training graphs

# Bugs

* Many Elixir warnings
* When creating a new example from the Predictions or Test screen, clicking on
the example text to label it will cause it to reset. This is really annoying.
Use a two-step editing process for now.
* Projects support broken in some ways (training and testing)

# Notes

Hairy Text uses a custom DETS-based storage system shim for training examples, logs, etc.
that integrates with Elixir's built in Ecto database framework (but only for
trivial parts of its functionality).

The connection to the Python-based NLP backend uses ErlPort

# Motivation

I wanted [Prodigy](https://prodi.gy/) but can't afford such bourgeoisie things.

# Requirements

* Elixir 1.10+
* Phoenix 1.5 + LiveView 
* Python 3.6+
* Spacy NLP toolkit for Python

# Installation

First, grab the code:

```
$ git clone https://github.com/tlack/hairytext/
```

Then, install Spacy for Python. You'll need a recent version of Python. Consider using virtualenv with Hairytext. FYI, The Python code is in priv/python

```
$ pip install spacy
```

Next, configure the default username/password:
```
$ vim config/config.exs
```

Finally, install Elixir dependencies and start server:

```
$ npm install --prefix assets
$ mix deps.get
$ iex -S mix phx.server
```

Then open http://localhost:4141 to start playing. The default username and password is `admin`:`sohairy`

# API

```
$ curl 'http://localhost:4141/api/predict/9d00fa70-df5c-4a3a-9f0d-8c53f3345417?text=i+am+live+on+twitch' | json_pp
{
	"text" : "i am live on twitch",
		"label" : "good",
		"label_confidence" : 0.999650120735168,
		"entities" : {
			"service" : "twitch"
		}
}
```

Add a new example to an image classification project:
```
$ curl https://example.com/test/someimage.jpg -o test.jpg
$ curl -X POST -F "image=@test.jpg" "http://localhost:4141/api/example/16700ec8-dab3-4d53-bcee-9b5e2ea52d3d"
```

Add a new example image to a project using its URL:
```
$ curl -X POST -F "image=http://example.com/images/1.jpg" \
		"http://localhost:4141/api/example/16700ec8-dab3-4d53-bcee-9b5e2ea52d3d" 
```

Add a new example, with a known label, to a project:
```
$ curl -X POST -F "image=http://example.com/images/1.jpg" \
		-F "label=yellow" \
		"http://localhost:4141/api/example/16700ec8-dab3-4d53-bcee-9b5e2ea52d3d" 
```

# Use from iex shell

Make a prediction for some new text. This returns the raw Spacy result format.

```
iex(48)> Spacy.predict("i want to go live on whuwhuwhaaaaat at 7am")
	%{
		'classification' => %{
			[] => 0.9619296193122864,
			'bad' => 0.03623370826244354,
			'good' => 0.9784072041511536
		},
		'entities' => [["service", "whuwhuwhaaaaat"], ["when", "7am"]],
		'text' => "i want to go live on whuwhuwhaaaaat at 7am"
	}
```

See the raw data about an example in the system:

```
iex(418)> HT.Data.list_examples |> List.last |> Map.get(:id) |> HT.Data.get_example!
%HT.Data.Example{
__meta__: #Ecto.Schema.Metadata<:built, "examples">,
	entities: %{},
	id: "e94e1954-0548-4f51-9570-e63cd298d2d7",
	image: nil,
	inserted_at: ~U[2020-04-30 04:05:34.965387Z],
	label: "bad",
	project: "9d00fa70-df5c-4a3a-9f0d-8c53f3345417",
	source: nil,
	status: nil,
	text: "i hate when people start live streaming. twitch sucks.",
	updated_at: ~U[2020-05-02 06:42:11.799197Z]
}
```

There is a handy utility feature to use when you have a bulk of images to label.

First, copy images from your examples directory into the HairyText
`image_examples/` subdirectory for your project. Have your HairyText project ID
at hand for this process (you can find it editing project settings).

```
$ find /tmp/my-new-examples/ -type f -name \*png | shuf | head -250 > example-list.txt
$ cp `cat example-list.txt` ~/hairy-text-path/image_examples/16700ec8-dab3-4d53-bcee-9b5e2ea52d3d
```

Now we have them in the right path for HairyText to manipulate, but we need to get them into the database.
Luckily HairyText provides a convenience function to do this.

```
iex> Util.upsert_examples_from_image_folder()
```
