addprocs(CPU_CORES-2) # ajout de plusieurs coeurs
Pkg.add("DecisionTree")
Pkg.add("Images")
Pkg.add("DataFrames")
Pkg.add("BackpropNeuralNet")
Pkg.add("XGBoost")


using Images
using Color
using DataFrames
using DecisionTree
using BackpropNeuralNet
using XGBoost

#image de test
img = imread("/home/divanov/kaggle/Julia_char/trainResized/1.Bmp")
temp = reinterpret(Float64, float64(img))
temp = convert(Image{Gray}, temp)
temp = convert(Array{Gray}, temp)
temp = convert(Array{Float64}, temp)
typeof(temp)
if ndims (temp) == 3
  temp = mean(temp.data, 1)
end

#Conversion en NB
function convert_to_grayscale(img)
  temp = reinterpret(Float32, float32(img))
  temp = convert(Image{Gray}, temp)
  temp = convert(Array{Gray}, temp)
  temp = convert(Array{Float32}, temp)
  if((mean(temp[1:19,1])+mean(temp[20,1:19])+mean(temp[2:20,20])+mean(temp[1,2:20]))/4>mean(temp))
    temp=1-temp
  end
  return(temp)
end

# Sampling data :
function getOccurrences(levels,y)
  occurrence = zeros(1,length(levels))
  for(i) in levels
    occ=find(x->(x == i), y)
    occurrence[find(x->(x==i),levels)]=length(occ)
  end
  return int(occurrence)
end

function getSample(y,lengthSample,nbOccMin)
  levels=unique(y)
  occurrence=zeros(1,length(levels))
  length(find(x->(x<nbOccMin),occurrence))
  sample=rand(1:length(y),lengthSample)
  while(length(find(x->(x<nbOccMin),occurrence))>0)
    sample=rand(1:length(y),lengthSample)
    ySample=y[sample]
    occurrence=getOccurrences(levels,ySample)
  end
  return(sample)
end

#sampleTrain=getSample(y,4000,2)
#xTrain=x[sampleTrain,1:400]
#yTrain=labelsInfoTrain[sampleTrain,:Class]

#sampleTrain=getSample(y,4000,2)
#xTrain=x[sampleTrain,1:400]
#yTrain=labelsInfoTrain[sampleTrain,:Class]

path = "/home/divanov/kaggle/Julia_char"

# Les labels / classes
labelsInfoTrain = readtable("$(path)/trainLabels.csv")


# Lecture et transformation des donnees
function read_data(path, labelsInfo, imageSize)
  #initialising x matrix
  x= zeros(size(labelsInfo, 1), imageSize)
  for(index, idImage) in enumerate(labelsInfo[:ID])
    nameFile = "$(path)/$(idImage).Bmp"
    img = imread(nameFile)
    temp = convert_to_grayscale(img)
    x[index, :] = reshape(temp, 1, imageSize)
  end
  return x
end


xTrain = read_data("$(path)/trainResized", labelsInfoTrain, 400)
yTrain = labelsInfoTrain[:Class]
yTrain = map(x -> x[1], yTrain)
yTrain = int(yTrain)


labelsInfoTest = readtable("$(path)/sampleSubmission.csv")
xTest = read_data("$(path)/testResized", labelsInfoTest, 400)
xTrainT = xTrain[1:5000, :]
yTrainT = yTrain[1:5000]
length(unique(yTrainT)) #62, donc, on peut utiliser xTrainT, yTrainT comme sous-echantillon d'apprentissage

xTrainE = xTrain[5001:end, :]
yTrainE = yTrain[5001:end]
length(unique(yTrainE)) #62, donc, tous les caracteres sont representes dans l'echantillon d'evaluation

model = build_forest(yTrain, xTrain, 30, 700, 1)

predTest = apply_forest(model, xTest)

labelsInfoTest[:Class] = map(x -> string(char(x)), predTest)
writetable("$(path)/forestSubmission2.csv", labelsInfoTest, separator = ',', header = true)


param = ["max_depth"=>2, "eta"=>1, "objective"=>"multi:sotmax"]
num_round = 1000;
num_class = 62;

minimum(yTrainT)
maximum(yTrainT)
print(sort(unique(yTrainT)))

function homogenize(x::Int64)
  if(x>=97)
    x = x - 6
  end
  if(x>=65)
    x = x - 7
  end
  x = x - 48
  return(x)
end

function heterogenize(x::Int64)
  x = x + 48
  if(x>57)
    x = x+7
  end
  if(x>90)
    x = x+6
  end
  return(x)
end

homogenize(heterogenize(2))
heterogenize(homogenize(50))

yTrainT2 = map(x -> homogenize(x), yTrainT)
print(sort(unique(yTrainT2)))
bst = xgboost(xTrainT, num_round, label = yTrainT2, eta=0.1, max_depth=2, subsample = 0.5, num_class = num_class, objective="multi:softmax")
preds = predict(bst, xTrainE)
preds = int64(preds)
preds = map(x -> heterogenize(x), preds)


yTrainE

net = init_network([400, 500, 62])

train(net, xTrainT, yTrainT)
predNet = net_eval(net, xTrainE)


#Je ne sais plus a quoi servaient les fonctions unitarise, misses et error
unitarise = function(x::Integer)
  if(x == 0)
    return(x)
  else
    return(1)
  end
end

misses = function(vector1, vector2)
  temp = vector1 - vector2
  temp = map(x -> unitarise(x), temp)
  return(sum(temp))
end

error = function(vector1, vector2)
  return(misses(vector1, vector2)/length(vector1))
end

misses(preds, yTrainE)

yTrain2 = map(x -> homogenize(x), yTrain)
bst = xgboost(xTrain, num_round, label = yTrain2, eta=0.1, max_depth=2, subsample = 0.5, num_class = num_class, objective="multi:softmax")
preds = predict(bst, xTest)
preds = int64(preds)
preds = map(x -> heterogenize(x), preds)

labelsInfoTest[:Class] = map(x -> string(char(x)), preds)
writetable("$(path)/gbmSubmission.csv", labelsInfoTest, separator = ',', header = true)


accuracy = nfoldCV_forest(yTrain, xTrain, 10, 700, 3, 0.1);
println(mean(accuracy));
print(typeof(accuracy))

#addprocs(CPU_CORES-1)
#nprocs()
#procs()
#help(rmprocs)
#nworkers()
#workers()

#help(build_adaboost_stumps)
@less(build_forest(yTrain, xTrain, 20, 100, 0.5))

# On va optimiser les parametres de la foret avec Particle Swarm Optimisation
type testType
  value::FloatingPoint
  vect::Vector{FloatingPoint}
end

t = testType(1.0, float64({2.0, 3.0}))
print(t.value)
println(t.vect)

type Particle
  position::Vector{FloatingPoint}
  velocity::Vector{FloatingPoint}
  best_position::Vector{FloatingPoint}
  best_performance::FloatingPoint
  social_weight::FloatingPoint
  own_best_weight::FloatingPoint
end

#Petit test
float({1.0, 1.0})
initpos = float({1.0, 0.0})
initvel = float({0.0, 0.0})
initbp = float({0.0, 0.1})
p = Particle(initpos, initvel, initbp, 3.4, 1.5, 2.0)

typeof(particle)

type Swarm
  particles::Array{Particle}
  best_position::Vector{FloatingPoint}
  best_performance::FloatingPoint
end

best_particle = function(p1::Particle, p2::Particle)
  p1.best_performance >= p2.best_performance ? p1 : p2
end



distance{T<:FloatingPoint}(v1::Vector{T}, v2::Vector{T}) = (v2 - v1)'*(v2-v1)

distance(initpos, initbp)

distance(initvel, initbp)

particle_move = function(p::Particle, s::Swarm)
  p.position = p.position + p.velocity
  p.velocity = p.velocity + (p.best_position - p.position).*rand()*p.own_best_weight + (s.best_position - p.position).*rand()*p.social.weight
end
println(methods(distance))


function particle_bench(p::Particle, perf::Function)
  perfs::FloatingPoint = perf(p)
  if(perfs > p.best_performance)
    p.best_performance = perfs
    p.best_position = p.position
  end
end

function perf_kaggle{T<:FloatingPoint}(Particle, trainLabels, trainData, equivalence::Vector{T})
  position = Particle.position
  coeffs = float64(eqiuivalence') * float64(position)
  features = int(coeffs[1])
  forest_size = int(coeffs[2])
  subsampling = abs(coeffs[3])
  if(subsampling > 1)
    subsampling = 1
  end
  accuracy = nfoldCV_forest(trainLabels, trainData, features, forest_size, 5, subsampling = subsampling);
  return(accuracy)
end


function bind_data_perf{T<: FloatingPoint}(f::Function, trainLabels, trainData, equivalence::Vector{T})
  return(x -> f(x, trainLabels, tranData, equivalence))
end

particle_evolve = function(particle::Particle, swarm::Swarm, perf::Function)
  particle_move(particle, swarm)
  particle_bench(particle, perf)
  return(particle)
end

function testSq(x::FloatingPoint)
  x = x^2;
end


function swarm_evolve(s::Swarm, perf::Function)
  s.particles = pmap(f, particle_evolve(s.particles), err_stop = true)
  bp::Particle = reduce(best_particle, s.particles[1], s.particles)
  if(bp.best_performance > s.best_performance)
    s.best_performance = bp.best_performance
    s.best_position = bp.best_position
  end
end



