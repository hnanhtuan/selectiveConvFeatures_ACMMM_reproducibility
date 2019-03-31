close all;
dataset = datasets{dataset_idx};

% dim = [512, 1024, 2048, 4096, 8064];
dim = [-1, -0.7, -0.5, -0.3, -0.2, 0];
switch dataset
    case 'oxford5k'
        mAP_temb = [58.1, 66.1, 67.6, 67.0, 65.7, 61.6];
    case 'holidays'
        mAP_temb = [70.5, 76.0, 77.1, 75.2, 73.5, 69.0];
end

h1 = figure(1);
set(h1,'defaulttextinterpreter','latex');
hold on;
font = 17;
font1 = 25;
set(gca,'FontSize',font);
% xlim([0 24]);
plot(dim, squeeze(mAPs(dataset_idx, 1, :))*100,'Color','red','Marker','s','Linewidth',2);
hold on;
plot(dim, squeeze(mAPs(dataset_idx, 2, :))*100,'Color','green','Marker','o','Linewidth',2);
hold on;
plot(dim, squeeze(mAPs(dataset_idx, 3, :))*100,'Color','blue','Marker','v','Linewidth',2);
hold on;
plot(dim, squeeze(mAPs(dataset_idx, 4, :))*100,'Color','magenta','Marker','^','Linewidth',2);
hold on
plot(dim, mAP_temb,'Color','cyan','Marker','*','Linewidth',2);

ax = gca;
ax.XTick = [-1, -0.7, -0.5, -0.2, 0];
ax.XTickLabel = {'1','0.7','0.5','0.2','0'};
% ax.XTickLabelRotation = 20;
set(gcf, 'color', 'w');
ax.YMinorTick = 'on';
ax.YMinorGrid = 'on';
grid on
ylabel('mAP (\%)','fontsize', font1);
switch dataset
    case 'oxford5k'
        
    case 'holidays'
        ylim([60, 95]);
end

xlabel('$\alpha$', 'Interpreter','latex', 'fontsize', font1);
h = legend( '$CNN + \mathcal{M}_{MAX} +\phi_\Delta + \psi_d$', ...
        '$CNN + \mathcal{M}_{SUM} +\phi_\Delta + \psi_d$', ...
        '$CNN + \mathcal{M}_{SIFT} +\phi_\Delta + \psi_d$', ...
        '$CNN +\phi_\Delta + \psi_d$', ...
        '$SIFT +\phi_\Delta + \psi_d$','Location','south');
set(h,'Interpreter','latex')   
 
pause(1);
set(h1,'Units','Inches');
pos = get(h1,'Position');
set(h1,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])

set(gcf, 'color', 'w');

saveas(h1,['results/charts/exp_figure3/', dataset, '_mAP_affect_of_powernorm','.pdf'],'pdf'); 