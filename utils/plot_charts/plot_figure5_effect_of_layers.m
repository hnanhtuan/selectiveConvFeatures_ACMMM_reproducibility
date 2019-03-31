close all;
h1 = figure(1);
set(h1,'defaulttextinterpreter','latex');
hold on;

dataset = datasets{dataset_idx};

% dim = [512, 1024, 2048, 4096, 8064];
dim = [1, 2, 3, 4, 5];

font = 17;
font1 = 25;
set(gca,'FontSize',font);
% xlim([0 24]);
plot(dim, squeeze(mAPs(dataset_idx, 6, :)),'Color','red','Marker','s','Linewidth',2);
hold on;
plot(dim, squeeze(mAPs(dataset_idx, 5, :)),'Color','green','Marker','o','Linewidth',2);
hold on;
plot(dim, squeeze(mAPs(dataset_idx, 4, :)),'Color','blue','Marker','v','Linewidth',2);
hold on;
plot(dim, squeeze(mAPs(dataset_idx, 3, :)),'Color','magenta','Marker','^','Linewidth',2);
hold on
plot(dim, squeeze(mAPs(dataset_idx, 2, :)),'Color','cyan','Marker','*','Linewidth',2);
hold on
plot(dim, squeeze(mAPs(dataset_idx, 1, :)),'Color','black','Marker','<','Linewidth',2);

ax = gca;
ax.XTick = dim;
ax.XTickLabel = {'512-D','1024-D','2048-D','4096-D','8064-D'};
% ax.XTickLabelRotation = 20;
set(gcf, 'color', 'w');
ax.YMinorTick = 'on';
ax.YMinorGrid = 'on';
grid on
ylabel('mAP (\%)','fontsize', font1);
h = legend('conv5-3','conv5-2','conv5-1', 'conv4-3', 'conv4-2', 'conv4-1', 'Location','southeast');
set(h,'Interpreter','latex');

pause(1);
set(h1,'Units','Inches');
pos = get(h1,'Position');
set(h1,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
set(gcf, 'color', 'w');
saveas(h1,['results/charts/exp_figure5/', dataset, '_mAP_effect_of_layers.pdf'],'pdf'); 