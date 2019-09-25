# -*- coding: utf-8 -*-
from setuptools import setup


with open('../VERSION', 'rb') as f:
    version = f.read().decode('utf-8')
    version = version.split('-')[0]


setup(
    name = 'UrRtde',
    packages = ['rtde'],
    version = version,
    description = 'Real-Time Data Exchange (RTDE) python client + examples'
)
