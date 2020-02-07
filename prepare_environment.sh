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

if [[ -z "$GCLOUD_PROJECT" ]]
then
 echo "GCLOUD_PROJECT not set"
 echo "Set GCLOUD_PROJECT to $DEVSHELL_PROJECT_ID"
 export GCLOUD_PROJECT=$DEVSHELL_PROJECT_ID
fi

if [[ -z "$GCLOUD_REGION" ]]
then
 echo "GCLOUD_REGION not set"
 echo "Set GCLOUD_REGION to europe-west3"
 export GCLOUD_REGION=europe-west3
fi

if [[ -z "$GCLOUD_ZONE" ]]
then
 echo "GCLOUD_ZONE not set"
 echo "Set GCLOUD_ZONE to europe-west3-b"
 export GCLOUD_ZONE=europe-west3-b
fi

echo "GCLOUD_PROJECT: $GCLOUD_PROJECT"
echo "GCLOUD_REGION: $GCLOUD_REGION"
echo "GCLOUD_ZONE: $GCLOUD_ZONE"

echo "Setting gcloud config"
gcloud config set project $GCLOUD_PROJECT
gcloud config set compute/region $GCLOUD_REGION
gcloud config set compute/zone $GCLOUD_ZONE
gcloud config list

echo "Exporting GCLOUD_BUCKET, GOOGLE_APPLICATION_CREDENTIALS"
export GCLOUD_BUCKET=$GCLOUD_PROJECT-media
export GOOGLE_APPLICATION_CREDENTIALS=key.json

echo "Creating default network"
gcloud -q compute networks create default

echo "Creating App Engine app"
gcloud app create --region "$GCLOUD_REGION" 2>/dev/null

echo "Making bucket: gs://$GCLOUD_BUCKET"
gsutil mb gs://$GCLOUD_BUCKET

echo "Creating quiz-account Service Account"
gcloud iam service-accounts create quiz-account --display-name "Quiz Account"
gcloud iam service-accounts keys create $GOOGLE_APPLICATION_CREDENTIALS --iam-account=quiz-account@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

echo "Setting quiz-account IAM Role"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:quiz-account@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/owner
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:quiz-account@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/datastore.owner


echo "Installing dependencies"
npm install -g npm@6.11.3
npm update

echo "Creating Datastore entities"
node setup/add_entities.js

echo "Creating Cloud Pub/Sub topics"
gcloud pubsub topics create feedback
gcloud pubsub topics create answers

echo "Creating Cloud Spanner Instance, Database, and Tables"
gcloud spanner instances create quiz-instance --config=regional-$GCLOUD_REGION --description="Quiz instance" --nodes=1
gcloud spanner databases create quiz-database --instance quiz-instance --ddl "CREATE TABLE Feedback ( feedbackId STRING(100) NOT NULL, email STRING(100), quiz STRING(20), feedback STRING(MAX), rating INT64, score FLOAT64, timestamp INT64 ) PRIMARY KEY (feedbackId); CREATE TABLE Answers (answerId STRING(100) NOT NULL, id INT64, email STRING(60), quiz STRING(20), answer INT64, correct INT64, timestamp INT64) PRIMARY KEY (answerId DESC);"

echo "Enabling Cloud Functions API"
gcloud services enable cloudfunctions.googleapis.com

echo "Creating Cloud Functions"
gcloud -q functions deploy process-feedback --region $GCLOUD_REGION --runtime nodejs8 --trigger-topic feedback --source ./functions/feedback --stage-bucket $GCLOUD_BUCKET --entry-point subscribe
gcloud -q functions deploy process-answer --region $GCLOUD_REGION --runtime nodejs8 --trigger-topic answers --source ./functions/answer --stage-bucket $GCLOUD_BUCKET --entry-point subscribe

echo "Project ID: $GCLOUD_PROJECT"