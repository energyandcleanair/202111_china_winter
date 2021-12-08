# Notes on adding a R script to CREA server

There's `creaengine` which is a repository: [https://github.com/energyandcleanair/creaengine](https://github.com/energyandcleanair/creaengine)

In this repo, you have two things:
- API for the online platform [portal.energyandcleanair.org](portal.energyandcleanair.org)
- Engine: has scrapers for air quality data, but also the capacity to run R scripts.

## More about the "engine"
It's both a Python Flask application and Python CLI.

The Flask application is being run on Google App Engine (online).

What we want to do is send requests to this App Engine every day, with the relevant payload.


## Step 1: Clean the script & make it executable

- put data into a `data` folder
- run and see that it works
- be sure packages are being installed by the script (e.g. using `remotes::install_github`) and that they don't require user input (i.e. by specifying `upgrade=` and `update=`)
- no local file can be read: use the `raw.github...` url (the repository needs to be public)
- if you want to export files to GCS (and are using the `export` field in the config), you need to run the R script in a new directory, given by Python. In other words, you need to add this to your R script:
```R
folder <- {tmp_dir} # Used in rpy2, replaced by a temporary folder
setwd(folder)
```

Objective: the R script should be a standalone script that exports files to a dedicated folder.

Once it works, push modifications.

## Step 2: Create a config file for the script to be executed
The engine needs to know what to do, with what.


In this case, we tell the engine in a .json file:
- to launch a r script:
```json
"command": "run_script",
"rscript":{
       "url": "https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/scripts/tracker.R"
}
```

- and copy generated files on Google Cloud Storage:
```json=
"export": [
       {
         "dest_folder":"gs://crea-public/plots/mee/region/keyregions/tracker",
         "source_filepath":"results/*"
       }
     ]
```

The whole file can be found here: [https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/scripts/tracker.json](https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/scripts/tracker.json)

## Step 3: Test if it works using the CLI
From `engine` directory:
```bash
python main.py -u https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/scripts/tracker.json`
```

## Step 4: Create a 'Scheduled job'

```bash
gcloud scheduler jobs create app-engine tracker-china-2021 \
    --schedule="0 2 * * *" \
    --http-method=POST \
    --service=engine \
    --attempt-deadline=24h \
    --message-body="{\"config_url\":\"https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/scripts/tracker.json\"}" \
    --time-zone="Asia/Hong_Kong"
```

You can now see it here: [https://console.cloud.google.com/cloudscheduler?project=crea-aq-data](https://console.cloud.google.com/cloudscheduler?project=crea-aq-data)

Launch it, cross fingers, and wait... If it fails, you can see logs here: [https://console.cloud.google.com/logs/query?project=crea-aq-data](https://console.cloud.google.com/logs/query?project=crea-aq-data)

You should use the following query to see what's happening on the App Engine instance:
```
resource.type="gae_app"
resource.labels.module_id="engine"
log_name="projects/crea-aq-data/logs/appengine.googleapis.com%2Fstderr"
```