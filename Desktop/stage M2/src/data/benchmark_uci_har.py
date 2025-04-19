# init_environments.py
import torch
from torch.nn import CrossEntropyLoss
from torch.optim import Adam

from avalanche.logging import InteractiveLogger
from avalanche.evaluation.metrics import accuracy_metrics, loss_metrics
from avalanche.training.plugins import EvaluationPlugin

from avalanche.models import SimpleMLP
#from benchmark_uci_har import load_ucihar_dataset, create_activity_split_benchmark



def init_environments(data_dir, input_size=561, num_classes=6, device=None):
    # 1. Charger les données et créer le benchmark
    X, y = load_ucihar_dataset(data_dir)
    benchmark = create_activity_split_benchmark(X, y)

    # 2. Définir le device
    device = device or torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # 3. Modèle simple MLP
    model = SimpleMLP(input_size=input_size, hidden_size=128, output_size=num_classes)
    model.to(device)

    # 4. Optimizer et fonction de perte
    optimizer = Adam(model.parameters(), lr=0.001)
    criterion = CrossEntropyLoss()

    # 5. Évaluation plugin
    interactive_logger = InteractiveLogger()
    eval_plugin = EvaluationPlugin(
        accuracy_metrics(minibatch=True, epoch=True, experience=True, stream=True),
        loss_metrics(minibatch=True, epoch=True, experience=True, stream=True),
        loggers=[interactive_logger]
    )

    return model, optimizer, criterion, eval_plugin, benchmark.train_stream, benchmark.test_stream, device, benchmark
