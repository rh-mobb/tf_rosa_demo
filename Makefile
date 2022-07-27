public:
	tf plan -out rosa.plan \
		-var "cluster_name=rosa-public" \
		-var "enable_private_link=false" \
		-var "enable_sts=true"
	tf apply rosa.plan

privatelink:
	tf plan -out rosa.plan \
		-var "cluster_name=rosa-public" \
		-var "enable_private_link=true" \
		-var "enable_sts=true"
	tf apply rosa.plan

pl: privatelink

private-link: privatelink

private_link: privatelink


destroy:
	tf destroy

help:
	@echo "Usage: make public|privatelink|destroy"
