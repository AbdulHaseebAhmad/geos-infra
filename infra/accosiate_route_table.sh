#!/bin/bash



associate_route_table(){

	ASSOCIATION_ID=$(aws ec2 associate-route-table \
	    --route-table-id "$ROUTE_TABLE_ID" \
	    --subnet-id "$SUBNET_ID" \
	    --query "AssociationId" \
	    --output text)


	if [[ $? -ne 0 ]];
	then
		log "the route table could not be associated to the resource"
                return 1

	fi

	log "your Route table has succesfully been associated with the resource, ASSOCIATION_ID: $ASSOCIATION_ID"
        echo "your Route table has succesfully been associated with the resource, ASSOCIATION_ID: $ASSOCIATION_ID"
        return 0


}
