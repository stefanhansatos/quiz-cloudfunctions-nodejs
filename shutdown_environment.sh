#@IgnoreInspection BashAddShebang

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

echo "Exporting MEDIA_BUCKET, APP_CREDENTIALS"
export GCLOUD_BUCKET=$GCLOUD_PROJECT-media
export GOOGLE_APPLICATION_CREDENTIALS=key.json

echo "Deleting Cloud Spanner Instance, Database, and Table"
gcloud -q spanner instances delete quiz-instance

echo "Deleting Cloud Function"
gcloud -q functions delete process-feedback --region $GCLOUD_REGION
gcloud -q functions delete process-answer --region $GCLOUD_REGION

echo "Deleting Cloud Pub/Sub topic"
gcloud -q pubsub topics delete feedback answers

echo "Deleting quiz-account Service Account"
gcloud -q iam service-accounts delete quiz-account@$GCLOUD_PROJECT.iam.gserviceaccount.com
rm $GOOGLE_APPLICATION_CREDENTIALS

echo "Deleting bucket: gs://$GCLOUD_BUCKET"
gsutil rm -r gs://$GCLOUD_BUCKET

echo "Deleting default network"
gcloud -q compute networks delete default
