=head1 LICENSE

  Copyright (c) 2012-2013 The European Bioinformatics Institute and
  Genome Research Limited. All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_license.html

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>

=head1 NAME

Bio::EnsEMBL::Compara::CAFEGeneFamilyNode

=head1 SYNOPSIS


=head1 DESCRIPTION

Specific class to handle CAFE tree nodes

=head1 INHERITANCE TREE

  Bio::EnsEMBL::Compara::CAFEGeneFamilyNode

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with an underscore (_).

=cut

package Bio::EnsEMBL::Compara::CAFEGeneFamilyNode;

use strict;
use Data::Dumper;

use base ('Bio::EnsEMBL::Compara::SpeciesTreeNode');

sub find_nodes_by_taxon_id_or_species_name {
    my ($self, $val, $is_leaf) = @_;
    my $genomeDBAdaptor = $self->adaptor->db->get_GenomeDBAdaptor();
    if ($is_leaf) {
        my $taxon_id = $genomeDBAdaptor->fetch_by_name_assembly($val)->taxon_id();
        print STDERR "$self->find_node_by_field_value(taxon_id, $taxon_id)\n";
        return $self->find_nodes_by_field_value('taxon_id', $taxon_id);
    }
    return $self->find_nodes_by_field_value('taxon_id', $val);
}


sub new_from_SpeciesTree {
    my ($self, $tree) = @_;
#    my $speciesTree = SUPER::new_from_NestedSet($tree);
    return $tree->cast('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode');
}


=head2 taxon_id

    Arg[1]      : (opt.) <int> Taxon ID
    Example     : my $taxon_id = $tree->taxon_id
    Description : Getter/Setter for the taxon_id of the node
    ReturnType  : scalar
    Exceptions  : none
    Caller      : general

=cut

sub taxon_id {
    my ($self, $taxon_id) = @_;
    if (defined $taxon_id) {
        $self->{'_taxon_id'} = $taxon_id;
    }
    return $self->{'_taxon_id'};
}

=head2 n_members

    Arg[1]      : (opt.) <int>
    Example     : my $n_members = $tree->n_memberse
    Description : Getter/Setter for the number of members in the node
                  (gene counts for leaves and CAFE-estimated counts for internal nodes)
    ReturnType  : scalar
    Exceptions  : none
    Caller      : general

=cut

sub n_members {
    my ($self, $n_members) = @_;
    if (defined $n_members) {
        $self->{'_n_members'} = $n_members;
    }
    return $self->{'_n_members'};
}

=head2 pvalue

    Arg[1]      : (opt.) <double> pvalue
    Example     : my $pvalue = $tree->pvalue
    Description : Getter/Setter for the pvalue of having an expansion or contraction
                  in the node
    ReturnType  : scalar
    Exceptions  : none
    Caller      : general

=cut

sub pvalue {
    my ($self, $pvalue) = @_;
    if (defined $pvalue) {
        $self->{'_pvalue'} = $pvalue;
    }
    return $self->{'_pvalue'};
}

sub pvalue_lim {
    my ($self) = @_;
    return 0.01;
}

=head2 is_node_significant

    Arg[1]      : -none-
    Example     : if ($node->is_node_significant) {#do something with the node}
    Description : Returns if the node has a significant expansion or contraction
    ReturnType  : 0/1 (false/true)
    Exceptions  : none
    Caller      : general

=cut

sub is_node_significant {
    my ($self) = @_;
    return $self->pvalue < $self->pvalue_lim;
}

=head2 is_expansion

    Arg[1]      : -none-
    Example     : if($node->is_expansion) {#do something with node}
    Description : Returns if a given gene family has been expanded in this node
                  of the species tree even if the expansion is not significant
                  (i.e. only compares the number or members of the nodes with its parent)
    ReturnType  : 0/1 (false/true)
    Exceptions  : none
    Caller      : general

=cut

sub is_expansion {
    my ($self) = @_;
    if ($self->has_parent) {
        return $self->parent->is_expansion if ($self->is_node_significant && ($self->n_members == $self->parent->n_members));
        return 1 if ($self->n_members > $self->parent->n_members);
    }
    return 0;
}


=head2 is_contraction

    Arg[1]      : -none-
    Example     : if($node->is_contraction) {#do something with node}
    Description : Returns if a given gene family has been contracted in this node
                  of the species tree even if the contraction is not significant
                  (i.e. only compares the number or members of the nodes with its parent)
    ReturnType  : 0/1 (false/true)
    Exceptions  : none
    Caller      : general

=cut

sub is_contraction {
    my ($self) = @_;
    if ($self->has_parent) {
        return $self->parent->is_contraction if ($self->is_node_significant && ($self->n_members == $self->parent->n_members));
        return 1 if ($self->n_members < $self->parent->n_members);
    }
    return 0;
}


1;