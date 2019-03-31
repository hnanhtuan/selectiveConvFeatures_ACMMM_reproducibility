% clc

for i=1:length(datasets)
fprintf('------------------------------------------------------\n');
fprintf('|                       %8s                     |\n', upper(datasets{i}));
fprintf('|  Method  | MAX-mask | SUM-mask | SIFT-mask |  None |\n');
fprintf('------------------------------------------------------\n');
fprintf('| %8s |   %.02f  |   %.02f  |   %.02f   | %.02f |\n', ...
        upper(enc_methods{1}), mAPs(i, 1, 1)*100, mAPs(i, 1, 2)*100, mAPs(i, 1, 3)*100, mAPs(i, 1, 4)*100);
fprintf('| %8s |   %.02f  |   %.02f  |   %.02f   | %.02f |\n', ...
        upper(enc_methods{2}), mAPs(i, 2, 1)*100, mAPs(i, 2, 2)*100, mAPs(i, 2, 3)*100, mAPs(i, 2, 4)*100);
fprintf('| %8s |   %.02f  |   %.02f  |   %.02f   | %.02f |\n', ...
        upper(enc_methods{3}), mAPs(i, 3, 1)*100, mAPs(i, 3, 2)*100, mAPs(i, 3, 3)*100, mAPs(i, 3, 4)*100);
fprintf('| %8s |   %.02f  |   %.02f  |   %.02f   | %.02f |\n', ...
        upper(enc_methods{4}), mAPs(i, 4, 1)*100, mAPs(i, 4, 2)*100, mAPs(i, 4, 3)*100, mAPs(i, 4, 4)*100);
fprintf('------------------------------------------------------\n');
end
