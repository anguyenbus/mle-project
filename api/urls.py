"""
URL patterns and their views
"""

from django.urls import path

from . import views
urlpatterns = [
    path('parse', views.parse),
    path('stream', views.stream, name='stream'),
    path('batch', views.batch, name='batch'),
    path('health', views.health),
    path('parse_dummy', views.parse_dummy),
]
