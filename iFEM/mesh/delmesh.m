function [node,elem] = delmesh(node,elem,expr)
%% DELMESH delete part of the mesh 

dim = size(node,2); elemdim = size(elem,2);
%% delete element
switch elemdim
    case 3
        center = (node(elem(:,1),:)+node(elem(:,2),:)+node(elem(:,3),:))/3;
    case 4    
        center = (node(elem(:,1),:) + node(elem(:,2),:) ...
                + node(elem(:,3),:) + node(elem(:,4),:))/4;
end
x = center(:,1);  y = center(:,2); %#ok<*NASGU>
if dim == 3
	z = center(:,3); %#ok<*NASGU>
end
idx = eval(expr);
elem(idx,:) = [];

%% delete vertices
isValidNode = false(size(node,1),1);
isValidNode(elem(:)) = true;
node = node(isValidNode,:);

%% shift index of element
Nnew = sum(isValidNode);
indexMap(isValidNode) = (1:Nnew)';
elem = indexMap(elem);