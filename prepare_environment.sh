#@IgnoreInspection BashAddShebang

# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [[ -z "$PROJECT_ID" ]]
then
 echo "PROJECT_ID not set"
 echo "Set PROJECT_ID to $DEVSHELL_PROJECT_ID"
 export PROJECT_ID=$DEVSHELL_PROJECT_ID
fi

if [[ -z "$REGION" ]]
then
 echo "REGION not set"
 echo "Set REGION to europe-west3"
 export REGION=europe-west3
fi

if [[ -z "$ZONE" ]]
then
 echo "ZONE not set"
 echo "Set ZONE to europe-west3-b"
 export ZONE=europe-west3-b
fi

echo "PROJECT_ID: $PROJECT_ID"
echo "REGION: $REGION"
echo "ZONE: $ZONE"

echo "Setting gcloud config"
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
gcloud config list

echo "Exporting MEDIA_BUCKET, APP_CREDENTIALS"
export MEDIA_BUCKET=$PROJECT_ID-media
export APP_CREDENTIALS=key.json

echo "Creating default network"
gcloud -q compute networks create default

echo "Creating App Engine app"
gcloud app create --region "europe-west"

echo "Making bucket: gs://$MEDIA_BUCKET"
gsutil mb gs://$MEDIA_BUCKET

echo "Installing dependencies"
npm install -g npm@6.11.3
npm update

echo "Creating Datastore entities"
node setup/add_entities.js

echo "Creating Cloud Pub/Sub topics"
gcloud pubsub topics create feedback
gcloud pubsub topics create answers

echo "Creating Cloud Spanner Instance, Database, and Tables"
gcloud spanner instances create quiz-instance --config=regional-$REGION --description="Quiz instance" --nodes=1
gcloud spanner databases create quiz-database --instance quiz-instance --ddl "CREATE TABLE Feedback ( feedbackId STRING(100) NOT NULL, email STRING(100), quiz STRING(20), feedback STRING(MAX), rating INT64, score FLOAT64, timestamp INT64 ) PRIMARY KEY (feedbackId); CREATE TABLE Answers (answerId STRING(100) NOT NULL, id INT64, email STRING(60), quiz STRING(20), answer INT64, correct INT64, timestamp INT64) PRIMARY KEY (answerId DESC);"

echo "Enabling Cloud Functions API"
gcloud services enable cloudfunctions.googleapis.com

echo "Creating Cloud Functions"
gcloud -q functions deploy process-feedback --runtime nodejs8 --trigger-topic feedback --source ./functions/feedback --stage-bucket $MEDIA_BUCKET --entry-point subscribe
gcloud -q functions deploy process-answer --runtime nodejs8 --trigger-topic answers --source ./functions/answer --stage-bucket $MEDIA_BUCKET --entry-point subscribe

echo "Project ID: $PROJECT_ID"