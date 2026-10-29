--- English, math, and science words for identifier completion.
--- Earlier words rank higher for a given prefix.
local M = {}

local RAW = [[
rate ratio radius range random rank residual result return row relu rms recall regression
current count config cache cosine covariance coefficient class case clip column compute convolution
slack softmax score scale sample sequence sigma sigmoid sine size sum std step state status
shape stride standard scalar series speed size
value variance vector velocity volume voltage
mean matrix max min momentum mask model metric median mode mass message method module
gradient gamma gaussian gelu graph group gravity
delta data derivative depth device dimension distance dropout difference density debug
alpha accuracy attention average amplitude angle axis abs actual absolute area argument
beta batch bias base buffer bound block bool bandwidth
epsilon embedding encoder entropy epoch error expected exp energy equation exponent
lambda layer latent learning length linear loss log logit level lemma likelihood limit
theta tensor temperature time token total target threshold train type torque text
phi probability precision prior position padding parameter period phase polynomial
partial percentile poisson potential power pressure previous product prediction proof
omega output offset orthogonal optimizer orbit
input index integral inverse init info item inertia
norm number negative name nan neuron next node
query quantile quantum
hidden height hessian hypothesis head huber
kernel key
jacobian joint
force frequency float function feature factor file filter flux field friction fourier
weight width window wavelength warning
true false
zero
yield
acceleration acid amplitude atom
binomial bond bool
catalyst causal cell channel charge checkpoint clamp coeff complexity
contiguous convolution cortex cross cumulative cursor custom
decay denominator determinant deviation dict diffraction
direction distribution divisor downsample dtype
early eigenvalue eigenvector electron element embedding
enthalpy epoch equilibrium error euler
factorial false feature flatten focal float
focal force fraction frequency friction
gather gaussian gelu gene genome grad gradient
gravity group
hamming height hidden hinge hypothesis
index inertia inf input integer integral inverse
iou item
jacobian
kernel kl
label laplace latent layer leaky learning length
level likelihood limit linear list local log logarithm
logit loss lower
mae mantissa map markov mask mass matrix
max maximum mean median message method metric
microbatch min minimum mish mode model module molar
momentum multihead
name nan negative neuron newton next node norm normal normalize
nucleus number numerator
offset omega one optimizer orbit orthogonal output
padding param parameter partial path percentile period
permutation phase phi photon pi poisson polynomial
position posterior potential power precision predicate
prediction pressure previous prime prior probability
product projection protein proton
quantile quantum query
radius random range rank rate ratio reaction recall
regression relu residual resistance result return
rms roc row
sample scalar scale scheduler score selu sequence
series shape sigma sigmoid silu sine singular
size slack softmax solute solvent speed standard
state status std step stimulus stochastic stride
sum svd swish synapse
tangent target taylor temperature tensor text
theorem theta threshold time token top total torque
train transformer transpose true type
update upper upsample use user
value var variance vector velocity vocab voltage volume
warmup wavelength weight width window
zero
accuracy action active add address amount annotation
average axis
binary bit bound
column combination congruent
denominator derivative
denominator
expected
hash hamming
identifier
jitter
keyframe
latency
mantissa
namespace
offset
payload
quantile
runtime
schema
timeout
unique
valid
xref
]]

local function build()
  local seen = {}
  local buckets = {}
  for word in RAW:gmatch('%a+') do
    word = word:lower()
    if #word >= 2 and not seen[word] then
      seen[word] = true
      local key = word:sub(1, 1)
      local bucket = buckets[key]
      if not bucket then
        bucket = {}
        buckets[key] = bucket
      end
      bucket[#bucket + 1] = word
    end
  end
  return buckets
end

local buckets = build()

function M.lookup(prefix, limit)
  if type(prefix) ~= 'string' or prefix == '' then
    return {}
  end
  prefix = prefix:lower()
  if not prefix:match('^%a+$') then
    return {}
  end
  local bucket = buckets[prefix:sub(1, 1)]
  if not bucket then
    return {}
  end
  local out = {}
  local cap = limit or 8
  for _, word in ipairs(bucket) do
    if #word > #prefix and word:sub(1, #prefix) == prefix then
      out[#out + 1] = word
      if #out >= cap then
        break
      end
    end
  end
  return out
end

return M
