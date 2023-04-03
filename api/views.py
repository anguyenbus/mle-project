import json
import os
import pickle
import sys
import time
import numpy as np
from django.http import HttpResponseBadRequest, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from src.simple_linear_regr_utils import generate_data
from joblib import load, dump
import sys
sys.path.append("..")
from src.simple_linear_regr import SimpleLinearRegression

def process_request(request):
    """
    Extracts relevant information from the request object and returns them.

    Args:
        request (django.http.request.HttpRequest or dict): The request object containing the data.

    Returns:
        tuple: A tuple containing the extracted information from the request.
            The tuple has the following format: (cv_txt, request_id, threshold, customer, max_length)

    """
    # Extract the relevant data from the request object
    input_value = request.get("input_value", "")

    # Print some information for debugging purposes
    print(f"Received input: {input_value}")

    if "," in input_value:
        batch = True
        input_value = [[float(value)] for value in input_value[1:-1].split(',')]
        print(f"input values: {input_value}")
        input_value = np.array(input_value)
    else:
        batch = False
        input_value = input_value.replace("\"","")
        input_value = np.array([float(input_value)], dtype='float64')
    # Return the extracted data as a tuple
    return batch, input_value

def load_model():
    model = SimpleLinearRegression()
    model_file_path = 'models/model.joblib'
    if os.path.exists(model_file_path):
        model = load(model_file_path)
        print('Model loaded successfully!')
    else:
        print(f'Error: model file "{model_file_path}" does not exist')
        X_train, y_train, X_test, y_test = generate_data()
        model.fit(X_train, y_train)
        dump(model, 'models/model.joblib')

    return model


@csrf_exempt
def parse(request):
    # Load the saved model from the file
    model = load_model()
    # request can be either a dict (batch services) or a HttpRequest class
    if not isinstance(request, dict):
        if request.method != "POST":
            return HttpResponseBadRequest(
                "Please use POST request.", status=400
            )
        request = request.POST

    batch, input_value = process_request(request=request)
    # predict
    predictions = model.predict(input_value).tolist()

    return JsonResponse({"status": "ok", "data": predictions}, status=200)

@csrf_exempt
def stream(request):
    # Load the saved model from the file
    model = load_model()

    # request can be either a dict (batch services) or a HttpRequest class
    if not isinstance(request, dict):
        if request.method != "POST":
            return HttpResponseBadRequest(
                "Please use POST request.", status=400
            )
        request = request.POST

    batch, input_value = process_request(request=request)
    # predict
    if not batch:
        predictions = model.predict(input_value).tolist()
    else:
        return JsonResponse({"status": "ok", "data": "Error! Batches provided, use /batch instead!"}, status=200)

    return JsonResponse({"status": "ok", "data": predictions}, status=200)

@csrf_exempt
def batch(request):
    # Load the saved model from the file
    model = load_model()

    # request can be either a dict (batch services) or a HttpRequest class
    if not isinstance(request, dict):
        if request.method != "POST":
            return HttpResponseBadRequest(
                "Please use POST request.", status=400
            )
        request = request.POST

    batch, input_value = process_request(request=request)
    # predict
    if batch:
        predictions = model.predict(input_value).tolist()
    else:
        return JsonResponse({"status": "ok", "data": "Error! Stream provided, use /stream instead!"}, status=200)

    return JsonResponse({"status": "ok", "data": predictions}, status=200)


def health(request):
    print("health check port: %s" % request.META["SERVER_PORT"])
    return JsonResponse({"status": "ok"}, status=200)


@csrf_exempt
def parse_dummy(request):
    """
    Returns a JSON like a CV being parsed. Test purpose only.
    """
    if request.method != "POST":
        return HttpResponseBadRequest("Please use POST request.", status=400)

    json_data = {
        "status": "ok",
        "data": [
            {
                "input_value": "122",
                "output_scores": [0.9340000153]
            },
            {
                "input_value": "[122,234]",
                "output_scores": [[0.9340000153],[0.4535]]
            },
        ],
    }

    return JsonResponse({"status": "ok", "data": json_data}, status=200)
