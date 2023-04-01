"""
URL patterns and their views
"""

from django.urls import path

from . import views
urlpatterns = [
    path('parse', views.parse),
    path('health', views.health),
    path('parse_dummy', views.parse_dummy),
]
