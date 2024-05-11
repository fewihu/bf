function k-all-pods
{
    kubectl get pods -Ao jsonpath='{range .items[*]}{@.metadata.name}{" | "}{@..spec..containers[*].image}{" | "}{@.status.phase}{" | "}{@.status.startTime}{"\n"}{end}'

}
