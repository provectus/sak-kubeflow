#!/usr/bin/env python3
import kfp
import json
import copy
import os
from kfp import components
from kfp import dsl

region = os.getenv("REGION",default = "us-east-1")
bucket = os.getenv("S3_BUCKET",default = "kubeflow-pipeline-data")
role = os.getenv("ROLE",default = "")
image = os.getenv("IMAGE",default = "382416733822.dkr.ecr.us-east-1.amazonaws.com/kmeans:1")

sagemaker_train_op = components.load_component_from_url('https://raw.githubusercontent.com/kubeflow/pipelines/master/components/aws/sagemaker/train/component.yaml')

channelObjList = []

channelObj = {
    "ChannelName": "",
    "DataSource": {
        "S3DataSource": {
            "S3Uri": "",
            "S3DataType": "S3Prefix",
            "S3DataDistributionType": "FullyReplicated",
        }
    },
    "CompressionType": "None",
    "RecordWrapperType": "None",
    "InputMode": "File",
}

channelObj["ChannelName"] = "train"
channelObj["DataSource"]["S3DataSource"][
    "S3Uri"
] = "s3://%s/mnist_kmeans_example/train_data" % bucket
channelObjList.append(copy.deepcopy(channelObj))


@dsl.pipeline(name="Training pipeline", description="SageMaker training job test")
def training(
    region=region,
    endpoint_url="",
    image=image,
    training_input_mode="File",
    hyperparameters={"k": "10", "feature_dim": "784"},
    channels=channelObjList,
    instance_type="ml.m5.2xlarge",
    instance_count=1,
    volume_size=50,
    max_run_time=3600,
    model_artifact_path="s3://%s/mnist_kmeans_example/output" % bucket,
    output_encryption_key="",
    network_isolation=True,
    traffic_encryption=False,
    spot_instance=False,
    max_wait_time=3600,
    checkpoint_config={},
    role=role,
):
    training = sagemaker_train_op(
        region=region,
        endpoint_url=endpoint_url,
        image=image,
        training_input_mode=training_input_mode,
        hyperparameters=hyperparameters,
        channels=channels,
        instance_type=instance_type,
        instance_count=instance_count,
        volume_size=volume_size,
        max_run_time=max_run_time,
        model_artifact_path=model_artifact_path,
        output_encryption_key=output_encryption_key,
        network_isolation=network_isolation,
        traffic_encryption=traffic_encryption,
        spot_instance=spot_instance,
        max_wait_time=max_wait_time,
        checkpoint_config=checkpoint_config,
        role=role,
    )


if __name__ == "__main__":
    kfp.compiler.Compiler().compile(training, os.getenv("OUTPUT",default = "training_pipeline.yaml"))
