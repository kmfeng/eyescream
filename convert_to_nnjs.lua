require 'nn'
json = require 'cjson'
local mp = require 'MessagePack'
mp.set_number'float'


m = {}
m[1] = torch.load('8x8.t7')
m[2] = torch.load('8x14.t7')
m[3] = torch.load('14x28.t7')

-- nnjs is HWD, keep in mind when saving weights
function convertToNNJS(mod)
   local out = {}
   if torch.type(mod) == 'nn.Sequential' then
      out.type = 'Sequential'
      out.modules = {}
      for i=1,#mod.modules do
	 out.modules[i] = convertToNNJS(mod.modules[i])
      end
   elseif torch.type(mod) == 'nn.JoinTable' then
      out.type = 'JoinTable'
      out.dimension = 1
   elseif torch.type(mod) == 'nn.Linear' then
      out.type = 'Linear'
      out.weight = mod.weight:storage():totable()
      out.bias = mod.bias:storage():totable()
   elseif torch.type(mod) == 'nn.ReLU' then
      out.type = 'ReLU'
   elseif torch.type(mod) == 'nn.View' then
      out.type = 'View'
      out.dims = m[1].modules[7].size:totable()
   elseif torch.type(mod) == 'nn.ParallelTable' then
      out.type = 'Parallel'
      out.modules = {}
      for i=1,#mod.modules do
	 out.modules[i] = convertToNNJS(mod.modules[i])
      end
   elseif torch.type(mod) == 'nn.Identity' then
      out.type = 'Identity'
   elseif torch.type(mod) == 'nn.SpatialConvolution' then
      out.type = 'SpatialConvolution'
      out.weight = mod.weight:transpose(2,4):transpose(2,3):contiguous():storage():totable()
      out.bias =  mod.bias:storage():totable()
      out.padH = mod.padH and mod.padH or mod.padding
      out.padW = mod.padW and mod.padW or mod.padding
   else
      error('unsupported module: ' ..  torch.type(mod))
   end
   return out
end
-----------------------------------
print(m[1])
enc = convertToNNJS(m[1])

f = io.open('8x8.json', 'w')
f:write(json.encode(enc))
f:close()

f = io.open('8x8.mpac', 'w')
f:write(mp.pack(enc))
f:close()

print('saved json and mpac for 8x8')
---------------------
print(m[2])

enc = convertToNNJS(m[2])

f = io.open('8x14.json', 'w')
f:write(json.encode(enc))
f:close()

f = io.open('8x14.mpac', 'w')
f:write(mp.pack(enc))
f:close()
print('saved json and mpac for 8x14')
---------------------------------
print(m[3])

enc = convertToNNJS(m[3])

f = io.open('14x28.json', 'w')
f:write(json.encode(enc))
f:close()

f = io.open('14x28.mpac', 'w')
f:write(mp.pack(enc))
f:close()
print('saved json and mpac for 14x28')
