#!/bin/bash

# Test EKS read-only access for developer IAM user
# Automatically detects namespaces with running pods

echo "🔍 Testing read-only access for developer user on EKS cluster"
echo "-------------------------------------------------------------"

# 1. Check cluster connectivity
echo "1️⃣ Checking cluster access..."
kubectl cluster-info || { echo "❌ Cannot access cluster"; exit 1; }

# 2. List namespaces with running pods
echo
echo "2️⃣ Detecting namespaces with running pods..."
NAMESPACES=$(kubectl get pods --all-namespaces --no-headers | awk '{print $1}' | sort | uniq)

if [ -z "$NAMESPACES" ]; then
  echo "⚠️  No namespaces with running pods detected."
  exit 0
else
  echo "✅ Found namespaces:"
  echo "$NAMESPACES" | sed 's/^/   - /'
fi

# Loop through namespaces and run checks
for NAMESPACE in $NAMESPACES; do
  echo
  echo "-------------------------------------------------------------"
  echo "🔹 Testing namespace: $NAMESPACE"
  echo "-------------------------------------------------------------"

  # List pods
  echo "3️⃣ Listing pods..."
  kubectl get pods -n "$NAMESPACE" || echo "❌ Failed to list pods"

  # Describe first pod
  FIRST_POD=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$FIRST_POD" ]; then
    echo
    echo "4️⃣ Describing pod: $FIRST_POD"
    kubectl describe pod "$FIRST_POD" -n "$NAMESPACE" || echo "❌ Failed to describe pod"
  else
    echo "⚠️  No pods found in namespace $NAMESPACE"
    continue
  fi

  # Try getting logs
  echo
  echo "5️⃣ Checking pod logs (first 10 lines)..."
  kubectl logs "$FIRST_POD" -n "$NAMESPACE" --tail=10 || echo "❌ Failed to view logs"

  # Try a restricted action (delete pod)
  echo
  echo "6️⃣ Attempting to delete pod (should fail)..."
  kubectl delete pod "$FIRST_POD" -n "$NAMESPACE" 2>&1 | grep -E "forbidden|denied" && echo "✅ Delete blocked as expected" || echo "⚠️  Unexpected: delete might have succeeded!"

  # Try applying a manifest (restricted)
  echo
  echo "7️⃣ Attempting to apply manifest (should fail)..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/pods/simple-pod.yaml 2>&1 | grep -E "forbidden|denied" && echo "✅ Apply blocked as expected" || echo "⚠️  Unexpected: apply might have succeeded!"

done

echo
echo "-------------------------------------------------------------"
echo "✅ Test complete. Review output for ✅ (allowed) and ⚠️/❌ (denied) actions."
echo "-------------------------------------------------------------"
