#@IgnoreInspection BashAddShebang

export REGION=europe-west3
export ZONE=europe-west1-b

gcloud config set project $DEVSHELL_PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
gcloud config list

echo "Exporting GCLOUD_PROJECT, GCLOUD_BUCKET, and GOOGLE_APPLICATION_CREDENTIALS"
export GCLOUD_PROJECT=$DEVSHELL_PROJECT_ID
export GCLOUD_BUCKET=$DEVSHELL_PROJECT_ID-media
export GOOGLE_APPLICATION_CREDENTIALS=key.json

echo "Deleting Cloud Spanner Instance, Database, and Table"
gcloud -q spanner instances delete quiz-instance

echo "Deleting Cloud Function"
gcloud -q functions delete process-feedback
gcloud -q functions delete process-answer

echo "Deleting Cloud Pub/Sub topic"
gcloud -q pubsub topics delete feedback answers

echo "Deleting quiz-account Service Account"
gcloud -q iam service-accounts delete quiz-account@$GCLOUD_PROJECT.iam.gserviceaccount.com
rm $GOOGLE_APPLICATION_CREDENTIALS

echo "Deleting bucket: gs://$GCLOUD_BUCKET"
gsutil rm -r gs://$GCLOUD_BUCKET

echo "Deleting Container Engine cluster"
gcloud container clusters delete quiz-cluster --zone europe-west3-a

echo "Deleting default network"
gcloud compute networks delete default
