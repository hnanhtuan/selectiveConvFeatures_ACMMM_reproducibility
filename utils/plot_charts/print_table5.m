%load('exp_table5.mat');

fprintf('|   max(WI, HI)    | %5d | %5d |\n', max_img_dims(1), max_img_dims(2));
fprintf('------------------------------------\n');
fprintf('| %8s | %5s | %.02f | %.02f |\n', datasets{2}, upper(mask_methods{2}), mAPs(2, 2, 1)*100, mAPs(2, 2, 2)*100);
fprintf('| %8s | %5s | %.02f | %.02f |\n', datasets{2}, upper(mask_methods{1}), mAPs(2, 1, 1)*100, mAPs(2, 1, 2)*100);
fprintf('| %8s | %5s | %.02f | %.02f |\n', datasets{1}, upper(mask_methods{2}), mAPs(1, 2, 1)*100, mAPs(1, 2, 2)*100);
fprintf('| %8s | %5s | %.02f | %.02f |\n', datasets{1}, upper(mask_methods{1}), mAPs(1, 1, 1)*100, mAPs(1, 1, 2)*100);

