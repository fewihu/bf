function k-all-pods
{
    kubectl get pods -Ao jsonpath='{range .items[*]}{@.metadata.name}{" | "}{@..spec..containers[*].image}{" | "}{@.status.phase}{" | "}{@.status.startTime}{"\n"}{end}'

}

function un-kc
{
    oldConfig=$(echo "$KUBECONFIG")
    unset KUBECONFIG
    echo "Unset KUBECONFIG: $oldConfig"
    echo "KUBECONFIG: $KUBECONFIG"
}
