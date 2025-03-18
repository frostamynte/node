#!/bin/bash
# Requires foundry curl -L https://foundry.paradigm.xyz | bash
declare -a wallet=("0xE4ebb1F829046Ec6425d0dD1E41a91A3f9B22824" "0x2Ed8F2c6F399A6B30dc30d62561fBfB6B54a7F3e")
declare -a rpc=(
	"https://api.zan.top/arb-sepolia"
	"https://base-sepolia.drpc.org"
	"https://sepolia.blast.io"
	"https://sepolia.optimism.io"
	"https://sepolia.unichain.org"
	"https://b2n.rpc.caldera.xyz/http"
)

func_balance () {
	value=$(cast balance $1 --rpc-url $2)
	echo $value/10^18 | bc -l | awk '{printf "%.6f\n", $0}'
}

for i in "${wallet[1]}" ; do
	echo "Checking balance for $i"
	for network in "${rpc[@]}" ; do
		echo $network
		func_balance $i $network
	done
done
