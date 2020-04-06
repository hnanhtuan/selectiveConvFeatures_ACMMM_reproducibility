close all

x = [1, 2, 3, 4, 5];

h1 = figure(1);
set(h1,'defaulttextinterpreter','latex');
hold on;
font = 17;
font1 = 25;
set(gca,'FontSize',font);
% xlim([0 24]);
plot(x, squeeze(mAPs(dataset_idx, 1, :)),'Color','red','Marker','s','Linewidth',2);
hold on;
plot(x, squeeze(mAPs(dataset_idx, 2, :)),'Color','green','Marker','o','Linewidth',2);
hold on;
plot(x, squeeze(mAPs(dataset_idx, 3, :)),'Color','blue','Marker','v','Linewidth',2);
hold on;
plot(x, squeeze(mAPs(dataset_idx, 4, :)),'Color','magenta','Marker','^','Linewidth',2);

ax = gca;
ax.XTick = x;
ax.XTickLabel = {'512-D','1024-D','2048-D','4096-D','8064-D'};
% ax.XTickLabelRotation = 20;
set(gcf, 'color', 'w');
ax.YMinorTick = 'on';
ax.YMinorGrid = 'on';
grid on
ylabel('mAP (\%)','fontsize', font1);
h = legend('$\mathcal{M}_{MAX} +\phi_\Delta + \psi_d$', ...
        '$\mathcal{M}_{SUM} +\phi_\Delta + \psi_d$', ...
        '$\mathcal{M}_{SIFT} +\phi_\Delta + \psi_d$', ...
        '$\phi_\Delta + \psi_d$', ...
        'Location','southeast');
set(h,'Interpreter','latex')      

pause(1);
set(h1,'Units','Inches');
pos = get(h1,'Position');
set(h1,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])

set(gcf, 'color', 'w');

if ~exist('results/', 'dir'), mkdir('results/'); end
if ~exist('results/exp3_figure4/', 'dir'), mkdir('results/exp3_figure4/'); end
saveas(h1,['results/exp3_figure4/', dataset, '_representation_dim_analysis.pdf'],'pdf'); 