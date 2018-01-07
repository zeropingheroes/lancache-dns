# lancache-dns

DNS server configuration files for running a lancache

## Requirements

- Ubuntu Server 16.04

## Installation

1. `git clone https://github.com/zeropingheroes/lancache-dns.git && cd lancache-dns`

## Configuration

All configuration is done via environment variables:

1. `cp .env.example .env`
2. `nano .env`

Alternatively set the environment variables manually by running:

`export VARIABLE=value`

## Usage

`sudo ./install.sh`
