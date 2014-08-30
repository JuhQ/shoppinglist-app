module = angular.module('ShoppingListModels', []);

ItemResource = steroids.data.resource 'items'

module.constant('Items', ItemResource)



#steroids data resources:add items item:string is_bought:boolean created_at:date bought_at:date