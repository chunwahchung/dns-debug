#!/bin/bash

# TODO: write results to file without extra piping
# TODO: switch case or something to specify what function to use "flags/arguments"
# TODO: get_node_ip_from_pod - move __out_csv to a separate out directory inside dns_debug
# TODO: run_dig_on_dns_pods - make a file for each pod
# TODO: run_dig_on_dns_pods - put each set of runs in a separate folder

readonly DNS_PODS=$(kubectl get po -n openshift-dns --no-headers | cut -d ' ' -f 1 | xargs)

get_node_ip_from_pod() {

    readonly __out_dir="node_pod_mapping"
    readonly __out_csv="node_pod_mapping_$(date +%m-%d-%Y-%T-%Z).csv"
    readonly __pods=$(kubectl get po -n default --no-headers | cut -d ' ' -f 1 | xargs)

    echo cluster,$(kubectl cluster-info | head -n 1 | cut -d ' ' -f 7 | xargs) >> $__out_csv
    echo pod,node >> $__out_csv


    for pod in $__pods; do 
        echo starting kubectl on $pod
        kubectl describe po $pod -n default | grep Node:
        echo $pod,$(kubectl describe po $pod | grep Node: | cut -d ':' -f 2 | xargs | cut -d '/' -f 1) >> $__out_csv
        echo
    done
}

get_logdna_nodename() {
    
    readonly __nodes=$(kubectl get nodes --no-headers | cut -d ' ' -f 1 | xargs)

    for node in $__nodes; do
        echo starting kubectl on $node
        echo logdna node name:
        kubectl describe node $node | grep csi.volume.kubernetes.io/nodeid
        kubectl describe node $node > node_info/$node-describe.txt
        echo
    done 
}

check_for_running_client_pods() {

    while :; do
        declare -i __running_pods=$(kubectl get po --no-headers | grep dns-perf-client | grep Running | wc -l | xargs)

        if [[ $__running_pods -ge 4 ]]; then
            kubectl get po
            echo There are $(kubectl get po --no-headers | wc -l) dns-perf-client pods running
            echo Checking which nodes each test pod is running on..
            get_node_ip_from_pod
            break
        fi
    done
}


run_dig_on_dns_pods() {

    readonly __hosts_list_dir="queries"    
    readonly __hosts_list="ibm-hosts.txt"
    __out_dir="dig_out"
    __out_file="dig_list_stdout_$(date +%m-%d-%Y-%T-%Z).txt"

    if [[ ! -d "$__out_dir" ]]; then 
        mkdir $__out_dir
    fi

    touch "$__out_dir/$__out_file"
    echo "$__out_dir/$__out_file"

    for pod in $DNS_PODS; do
        echo Running dig on pod $pod >> $__out_dir/$__out_file
        kubectl cp $__hosts_list_dir/$__hosts_list $pod:/root -n openshift-dns -c dns
        kubectl exec -it $pod -n openshift-dns -c dns -- dig -f /root/$__hosts_list >> $__out_dir/$__out_file
        kubectl exec -it $pod -n openshift-dns -c dns -- rm /root/$__hosts_list
        echo >> $__out_dir/$__out_file
    done
}

# get_dns_pod_logs() {

# }

# run_top_on_dns_pods() {

# }

# check_host_list() {
    
# }

main() {

    # get_node_ip_from_pod
    # get_logdna_nodename
    # run_dig_on_dns_pods
    check_for_running_client_pods
}

main && exit 0