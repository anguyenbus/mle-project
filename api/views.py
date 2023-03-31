import json
import os
import pickle
import sys
import time

from django.http import HttpResponseBadRequest, JsonResponse
from django.views.decorators.csrf import csrf_exempt

# Load the saved model from the file
with open("models/model.pkl", "rb") as f:
    MODEL = pickle.load(f)


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
    print(f"Received input. ID: {input_value}")

    # Return the extracted data as a tuple
    return input_value


@csrf_exempt
def parse(request):

    batch_services = True
    # request can be either a dict (batch services) or a HttpRequest class
    if not isinstance(request, dict):
        if request.method != "POST":
            return HttpResponseBadRequest(
                "Please use POST request.", status=400
            )
        request = request.POST
        batch_services = False

    input_value = process_request(request=request)
    if not input_value or len(input_value) > 80000:
        return [
            JsonResponse({"status": "ok", "data": []}, status=200),
            {"status": "ok", "data": []},
        ][batch_services]

    # predict
    predictions = MODEL.predict(input_value)

    if batch_services:
        return {"status": "ok", "data": predictions}
    else:
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
                "sentences": "i am a software engineer, c++, java \n",
                "id": 0,
                "conceptUris": [
                    "http://data.europa.eu/esco/skill/b633eb55-8f1f-4ae6-ab4c-2022ffe2cb7f",
                    "http://data.europa.eu/esco/skill/5b9cde20-f1b9-4adc-bfb3-dbf70b14138d",
                    "http://data.europa.eu/esco/skill/19a8293b-8e95-4de3-983f-77484079c389",
                ],
                "output_scores": [0.9340000153, 0.3639999926, 0.3339999914],
                "skills": [
                    "C++",
                    "use object-oriented programming",
                    "Java (computer programming)",
                ],
            },
            {
                "sentences": "i like programming web technology and research\n",
                "id": 1,
                "conceptUris": None,
                "output_scores": None,
                "skills": None,
            },
        ],
    }

    return JsonResponse({"status": "ok", "data": json_data}, status=200)
