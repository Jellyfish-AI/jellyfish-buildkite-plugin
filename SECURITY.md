# Security Policy

# Trust Assumptions
We assume that all of the following are trusted when using jellyfish-buildkite-plugin:

The buildkite client
The user with respect to obtaining and storing/setting the Jellyfish API key.

We assume the following may be only partially trusted:

DevOps API Events: while not authorized to read from the Jellyfish side it is still sending raw information to be stored an processed in the Jellyfish DB. These events shold be properly vetted and processed to ensure no malicious action is available. 

Your Jellyfish instance and all data sources that feed into Jellyfish (JIRA, GitHub, etc.)

## Supported Versions

We are currently supporting all version of this product. 

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

To report any vulnerabilities please follow the instructions at: https://jellyfish.co/learn/trust-center/security-advisories-and-bulletins/

or 

Contact: security@jellyfish.co
