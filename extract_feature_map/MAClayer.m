classdef MAClayer < dagnn.Filter
  properties
    method = 'max'
    opts = {'cuDNN'}
  end

  methods
    function outputs = forward(self, inputs, params)
      outputs{1} = vl_nnpool(inputs{1}, [size(inputs{1},1), size(inputs{1},2)], ...
                             'method', self.method, ...
                             self.opts{:}) ;
    end

    function [derInputs, derParams] = backward(self, inputs, params, derOutputs)
      derInputs{1} = vl_nnpool(inputs{1}, [size(inputs{1},1), size(inputs{1},2)], derOutputs{1}, ...
                               'method', self.method, ...
                               self.opts{:}) ;
      derParams = {} ;
    end

    function kernelSize = getKernelSize(obj)
      kernelSize = obj.poolSize ;
    end

    function outputSizes = getOutputSizes(obj, inputSizes)
      outputSizes = getOutputSizes@dagnn.Filter(obj, inputSizes) ;
      outputSizes{1}(3) = inputSizes{1}(3) ;
    end

    function obj = MAC(varargin)
      obj.load(varargin) ;
    end
  end
end
