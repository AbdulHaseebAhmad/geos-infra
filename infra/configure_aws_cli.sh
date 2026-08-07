#!/bin/bash

configure_aws_cli(){
        aws configure
        if [[ $? -ne 0 ]]; then
                aws configure
                aws sts get-caller-identity
                echo "Cli Has been configured with the above User id and account "

        else
                aws sts get-caller-identity
                echo "CLI has been already configured"
        fi
}
